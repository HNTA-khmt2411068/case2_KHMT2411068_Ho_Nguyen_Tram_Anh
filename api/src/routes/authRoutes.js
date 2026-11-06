const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

router.post('/register', authController.register);
router.post('/login', authController.login);

router.get('/me', authMiddleware, (req, res) => {
  return res.status(200).json(req.user);
});

module.exports = router;