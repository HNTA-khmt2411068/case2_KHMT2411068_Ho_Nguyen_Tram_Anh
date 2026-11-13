const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const statisticsController = require('../controllers/statisticsController');

router.get('/tasks', authMiddleware, statisticsController.getTaskStatistics);
router.get('/assignments', authMiddleware, statisticsController.getAssignmentStatistics);
router.get('/deadlines', authMiddleware, statisticsController.getDeadlineStatistics);

module.exports = router;