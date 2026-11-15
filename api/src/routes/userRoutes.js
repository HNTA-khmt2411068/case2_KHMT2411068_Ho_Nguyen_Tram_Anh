const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.get('/', userController.searchUsers);
router.get('/search', userController.searchUsers);
router.get('/:id', userController.getUserById);

module.exports = router;