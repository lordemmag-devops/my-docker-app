
const express = require('express');
const mongoose = require('mongoose');
const redis = require('redis');
const User = require('./models/User'); // Import User model
const cors = require('cors'); // Import cors

const app = express();

// Middleware
app.use(express.json()); // For parsing application/json
app.use(cors()); // Enable CORS for all routes

app.get('/', (req, res) => res.send('Hello from API!'));

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Connect to MongoDB using environment variables from docker-compose
const dbUser = process.env.MONGO_INITDB_ROOT_USERNAME;
const dbHost = process.env.DB_HOST || 'db';
const fs = require('fs');
const dbPass = fs.readFileSync('/run/secrets/db-password', 'utf8').trim();
const mongoURI = `mongodb://${dbUser}:${dbPass}@${dbHost}:27017/mydb?authSource=admin`;
mongoose.connect(mongoURI);

const db = mongoose.connection;
db.on('error', console.error.bind(console, 'MongoDB connection error:'));
db.once('open', () => {
  console.log('Connected to MongoDB');
});

// Connect to Redis with error handling
const client = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST || 'cache',
    port: process.env.REDIS_PORT || 6379
  }
});

client.on('error', (err) => {
  console.error('Redis error:', err);
});

client.connect().then(() => {
  console.log('Connected to Redis');
}).catch((err) => {
  console.error('Redis connection error:', err);
});

// Registration route
app.post('/register', async (req, res) => {
  try {
    const { username, email, password } = req.body;

    // Check if user already exists
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
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.listen(3000, () => console.log('API running on port 3000'));
