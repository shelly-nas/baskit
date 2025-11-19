const express = require('express');
const router = express.Router();
const { database, logger } = require('../../../shared/src');

router.get('/', async (req, res) => {
  const healthCheck = {
    service: 'list-service',
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    websocket: 'enabled',
  };

  try {
    const dbHealthy = await database.healthCheck();
    healthCheck.database = dbHealthy ? 'connected' : 'disconnected';
    
    if (!dbHealthy) {
      healthCheck.status = 'degraded';
      return res.status(503).json(healthCheck);
    }

    res.status(200).json(healthCheck);
  } catch (error) {
    logger.error('Health check failed:', error);
    healthCheck.status = 'error';
    res.status(503).json(healthCheck);
  }
});

router.get('/ready', async (req, res) => {
  const dbHealthy = await database.healthCheck();
  res.status(dbHealthy ? 200 : 503).json({ ready: dbHealthy });
});

router.get('/live', (req, res) => {
  res.status(200).json({ alive: true });
});

module.exports = router;
