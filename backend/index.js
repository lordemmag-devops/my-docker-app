
const express = require('express');
const mongoose = require('mongoose');
const redis = require('redis');

const app = express();
app.get('/', (req, res) => res.send('Hello from API!'));

mongoose.connect('mongodb://db:27017/mydb', { useNewUrlParser: true });
const client = redis.createClient({ host: 'cache' });

app.listen(3000, () => console.log('API running'));
