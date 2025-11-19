require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const { database, logger, errorHandler, requestLogger, corsOptions } = require('../../shared/src');

const healthRoutes = require('./routes/health.routes');
const productRoutes = require('./routes/product.routes');

const app = express();
const PORT = process.env.PORT || 3002;

app.use(helmet());
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

app.use('/api/health', healthRoutes);
app.use('/api/products', productRoutes);

app.use(errorHandler);

const startServer = async () => {
  try {
    await database.connect();
    app.listen(PORT, () => {
      logger.info(`Product Service running on port ${PORT}`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

process.on('SIGTERM', async () => {
  await database.close();
  process.exit(0);
});

startServer();
module.exports = app;
