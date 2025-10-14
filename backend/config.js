const fs = require('fs');
const dbPass = fs.readFileSync('/run/secrets/db-password', 'utf8').trim();

module.exports = {
  mongoURI: process.env.MONGO_URL || `mongodb://${process.env.MONGO_INITDB_ROOT_USERNAME}:${dbPass}@${process.env.DB_HOST || 'db'}:27017/mydatabase?authSource=admin`,
  redis: {
    host: process.env.REDIS_HOST || 'cache',
    port: process.env.REDIS_PORT || 6379
  },
  port: process.env.PORT || 3000,
  env: process.env.NODE_ENV || 'development'
};
