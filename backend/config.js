module.exports = {
  mongoURI: `mongodb://${process.env.MONGO_INITDB_ROOT_USERNAME}:${process.env.MONGO_INITDB_ROOT_PASSWORD}@${process.env.DB_HOST || 'db'}:27017/mydb?authSource=admin`,
  redis: {
    host: process.env.REDIS_HOST || 'cache',
    port: process.env.REDIS_PORT || 6379
  },
  port: process.env.PORT || 3000,
  env: process.env.NODE_ENV || 'development'
};
