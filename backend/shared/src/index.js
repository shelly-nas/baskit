const database = require('./database');
const logger = require('./logger');
const errors = require('./errors');
const middleware = require('./middleware');

module.exports = {
  database,
  logger,
  ...errors,
  ...middleware,
};
