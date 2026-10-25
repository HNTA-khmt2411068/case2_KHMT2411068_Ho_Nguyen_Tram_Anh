const express = require('express');
const router = express.Router();
const taskController = require('../controllers/taskController');
const verifyToken = require('../middleware/authMiddleware');

router.use(verifyToken);
router.get('/', taskController.getTasks);
router.get('/:id', taskController.getTaskById);

module.exports = router;