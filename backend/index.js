
const express = require('express');
const mongoose = require('mongoose');
const redis = require('redis');

const app = express();
app.get('/', (req, res) => res.send('Hello from API!'));

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Connect to MongoDB using environment variables from docker-compose
const dbUser = process.env.MONGO_INITDB_ROOT_USERNAME;
const dbPass = process.env.MONGO_INITDB_ROOT_PASSWORD;
const dbHost = process.env.DB_HOST || 'db';
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

app.listen(3000, () => console.log('API running on port 3000'));
