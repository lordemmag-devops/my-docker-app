
const express = require('express');
const mongoose = require('mongoose');
const redis = require('redis');
const { body, validationResult } = require('express-validator');
const User = require('./models/User');
const cors = require('cors');
const config = require('./config');
const fs = require('fs');
const client = require('prom-client'); // Import prom-client

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

// Middleware
app.use(express.json());
app.use(cors());

// Connect to MongoDB
console.log('Attempting to connect to MongoDB...');
const dbPass = fs.readFileSync('/run/secrets/db-password', 'utf8').trim();
const mongoURIWithPass = config.mongoURI.replace('${process.env.MONGO_INITDB_ROOT_PASSWORD}', dbPass);

mongoose.connect(mongoURIWithPass);

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

app.listen(config.port, () => console.log(`API running on port ${config.port}`));
