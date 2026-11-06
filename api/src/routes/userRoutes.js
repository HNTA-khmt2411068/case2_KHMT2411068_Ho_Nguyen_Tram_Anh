const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

router.get('/test', (req, res) => {
  return res.json({ status: 'Route /api/users hoat dong tot!' });
});

router.get('/', userController.getAllUsers);
router.get('/search', userController.searchUsers);
router.get('/:id', userController.getUserById);

module.exports = router;