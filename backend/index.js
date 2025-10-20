
const express = require('express');
const mongoose = require('mongoose');
const redis = require('redis');
const { body, validationResult } = require('express-validator');
const { User, Message } = require('./models/User');
const cors = require('cors');
const config = require('./config');
const fs = require('fs');
const client = require('prom-client'); // Import prom-client
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');

const app = express();

// Prometheus metrics setup
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ prefix: 'node_app_' });

app.get('/metrics', async (req, res) => {
  console.log('Metrics endpoint hit');
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

// Centralized error handling middleware
app.use((err, req, res, next) => {
  console.error('Centralized error handler:', err.stack);
  res.status(500).send('Something broke!');
});

// File upload configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = '/app/uploads';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1E9)}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  }
});

const upload = multer({ 
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|pdf|doc|docx|txt|zip/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    if (mimetype && extname) {
      return cb(null, true);
    }
    cb(new Error('Invalid file type'));
  }
});

// Middleware
app.use(express.json());
app.use(cors());
app.use('/uploads', express.static('/app/uploads'));

// Connect to MongoDB
console.log('Attempting to connect to MongoDB...');
mongoose.connect(config.mongoURI);

const db = mongoose.connection;
db.on('error', (err) => {
  console.error('MongoDB connection error:', err);
  process.exit(1); // Exit process on MongoDB connection error
});
db.once('open', () => {
  console.log('Connected to MongoDB');
});

// Connect to Redis
console.log('Attempting to connect to Redis...');
const redisClient = redis.createClient({ // Renamed client to redisClient to avoid conflict with prom-client
  socket: {
    host: config.redis.host,
    port: config.redis.port
  }
});

redisClient.on('error', (err) => {
  console.error('Redis error:', err);
});

redisClient.connect().then(() => {
  console.log('Connected to Redis');
}).catch((err) => {
  console.error('Redis connection error:', err);
  process.exit(1); // Exit process on Redis connection error
});

// Routes
app.get('/', (req, res) => res.send('Hello from API!'));

app.get('/health', async (req, res) => {
  console.log('Health check endpoint hit');
  const healthcheck = {};
  try {
    // Check MongoDB connection
    await mongoose.connection.db.admin().ping();
    healthcheck.mongodb = 'OK';
  } catch (e) {
    healthcheck.mongodb = 'Error: ' + e.message;
  }

  try {
    // Check Redis connection
    await redisClient.ping(); // Use redisClient here
    healthcheck.redis = 'OK';
  } catch (e) {
    healthcheck.redis = 'Error: ' + e.message;
  }

  if (healthcheck.mongodb === 'OK' && healthcheck.redis === 'OK') {
    res.status(200).json(healthcheck);
  } else {
    res.status(500).json(healthcheck);
  }
});

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_here'; // In production, use environment variable

// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ message: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};

// Registration route with validation
app.post(
  '/register',
  [
    body('username').isLength({ min: 3 }).withMessage('Username must be at least 3 characters long'),
    body('email').isEmail().withMessage('Please enter a valid email address'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters long'),
  ],
  async (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { username, email, password } = req.body;

      let user = await User.findOne({ email });
      if (user) {
        return res.status(400).json({ message: 'User with that email already exists' });
      }

      user = await User.findOne({ username });
      if (user) {
        return res.status(400).json({ message: 'User with that username already exists' });
      }

      user = new User({
        username,
        email,
        password,
      });

      await user.save();
      res.status(201).json({ message: 'User registered successfully' });
    } catch (error) {
      console.error('Registration error:', error);
      next(error); // Pass error to centralized error handler
    }
  }
);

// Login route
app.post('/login', async (req, res, next) => {
  try {
    const { username, password } = req.body;

    const user = await User.findOne({ username });
    if (!user) {
      return res.status(400).json({ message: 'Invalid username or password' });
    }

    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(400).json({ message: 'Invalid username or password' });
    }

    // Generate JWT token
    const token = jwt.sign({ userId: user._id, username: user.username }, JWT_SECRET, { expiresIn: '24h' });

    res.json({ message: 'Login successful', token, user: { id: user._id, username: user.username } });
  } catch (error) {
    console.error('Login error:', error);
    next(error);
  }
});

// Send message route (protected)
app.post('/messages', authenticateToken, async (req, res, next) => {
  try {
    const { text, type = 'text', emoji, sticker } = req.body;
    const senderId = req.user.userId;

    // Validate based on message type
    if (type === 'text' && !text?.trim()) {
      return res.status(400).json({ message: 'Message text is required' });
    }
    if (type === 'emoji' && !emoji) {
      return res.status(400).json({ message: 'Emoji is required' });
    }


    const messageData = {
      sender: senderId,
      type,
    };

    if (type === 'text') messageData.text = text.trim();
    if (type === 'emoji') messageData.emoji = emoji;


    const message = new Message(messageData);
    await message.save();
    await message.populate('sender', 'username');

    res.status(201).json(message);
  } catch (error) {
    console.error('Send message error:', error);
    next(error);
  }
});

// File upload route (protected)
app.post('/upload', authenticateToken, upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    const senderId = req.user.userId;
    const isImage = /\.(jpg|jpeg|png|gif)$/i.test(req.file.originalname);
    
    const messageData = {
      sender: senderId,
      type: isImage ? 'image' : 'file',
      fileName: req.file.originalname,
      fileUrl: `/uploads/${req.file.filename}`,
      fileSize: req.file.size,
    };

    const message = new Message(messageData);
    await message.save();
    await message.populate('sender', 'username');

    res.status(201).json(message);
  } catch (error) {
    console.error('File upload error:', error);
    next(error);
  }
});

// Get messages route (protected)
app.get('/messages', authenticateToken, async (req, res, next) => {
  try {
    const messages = await Message.find()
      .populate('sender', 'username')
      .sort({ timestamp: 1 })
      .limit(100); // Limit to last 100 messages for simplicity

    res.json(messages);
  } catch (error) {
    console.error('Get messages error:', error);
    next(error);
  }
});

app.listen(config.port, () => console.log(`API running on port ${config.port}`));
