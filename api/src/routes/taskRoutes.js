const express = require('express');
const router = express.Router();
const taskController = require('../controllers/taskController');
const taskShareController = require('../controllers/taskShareController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.get('/', taskController.getTasks);
router.post('/', taskController.createTask);
router.get('/:id', taskController.getTaskById);
router.put('/:id', taskController.updateTask);
router.get('/:id/activities', taskController.getTaskActivities);
router.post('/:id/assignees', taskController.assignTask);
router.delete('/:id', taskController.deleteTask);

router.post('/:taskId/shares', taskShareController.shareTask);
router.get('/:taskId/shares', taskShareController.getShares);
router.delete('/:taskId/shares/:shareId', taskShareController.revokeShare);

module.exports = router;