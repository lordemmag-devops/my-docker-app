
const express = require('express');
const mongoose = require('mongoose');
const redis = require('redis');

const app = express();
app.get('/', (req, res) => res.send('Hello from API!'));

// Connect to MongoDB with error handling
mongoose.connect('mongodb://db:27017/mydb', { 
  useNewUrlParser: true,
  useUnifiedTopology: true
});

const db = mongoose.connection;
db.on('error', console.error.bind(console, 'MongoDB connection error:'));
db.once('open', () => {
  console.log('Connected to MongoDB');
});

// Connect to Redis with error handling
const client = redis.createClient({ 
  host: 'cache',
  port: 6379
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
