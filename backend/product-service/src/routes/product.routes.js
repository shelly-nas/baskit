const express = require('express');
const router = express.Router();
const { asyncHandler } = require('../../shared/src');

router.get('/', asyncHandler(async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Get products endpoint - to be implemented',
    data: [],
  });
}));

router.get('/search', asyncHandler(async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Product search endpoint - to be implemented',
    query: req.query.q,
    data: [],
  });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Get product by ID - to be implemented',
    data: { id: req.params.id },
  });
}));

module.exports = router;
