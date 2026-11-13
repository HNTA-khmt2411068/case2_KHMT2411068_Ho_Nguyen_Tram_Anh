const express = require('express');
const router = express.Router();
const assignmentController = require('../controllers/assignmentController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.get('/:id/assignees', assignmentController.getAssignees);
router.post('/:id/assignees', assignmentController.assignTask);
router.patch('/:id/assignees/:userId', assignmentController.updateAssigneeRole);
router.delete('/:id/assignees/:userId', assignmentController.removeAssignee);

module.exports = router;