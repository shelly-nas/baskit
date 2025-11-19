require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const { database, logger, errorHandler, requestLogger, corsOptions } = require('../../shared/src');

const healthRoutes = require('./routes/health.routes');
const listRoutes = require('./routes/list.routes');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: corsOptions });

const PORT = process.env.PORT || 3003;

app.use(helmet());
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

// Make io available to routes
app.set('io', io);

app.use('/api/health', healthRoutes);
app.use('/api/lists', listRoutes);

app.use(errorHandler);

// WebSocket connection for real-time list updates
io.on('connection', (socket) => {
  logger.info('Client connected to WebSocket', { socketId: socket.id });

  socket.on('join-list', (listId) => {
    socket.join(`list:${listId}`);
    logger.info('Client joined list room', { listId, socketId: socket.id });
  });

  socket.on('leave-list', (listId) => {
    socket.leave(`list:${listId}`);
    logger.info('Client left list room', { listId, socketId: socket.id });
  });

  socket.on('disconnect', () => {
    logger.info('Client disconnected', { socketId: socket.id });
  });
});

const startServer = async () => {
  try {
    await database.connect();
    server.listen(PORT, () => {
      logger.info(`List Service running on port ${PORT}`);
      logger.info('WebSocket server enabled for real-time updates');
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
