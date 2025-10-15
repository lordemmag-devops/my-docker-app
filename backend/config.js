module.exports = {
  mongoURI: process.env.MONGO_URL || 'mongodb://db:27017/mydatabase',
  redis: {
    host: process.env.REDIS_HOST || 'cache',
    port: process.env.REDIS_PORT || 6379
  },
  port: process.env.PORT || 3000,
  env: process.env.NODE_ENV || 'development'
};
