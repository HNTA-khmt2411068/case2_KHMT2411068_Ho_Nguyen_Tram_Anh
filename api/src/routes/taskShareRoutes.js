const express = require('express');
const router = express.Router({ mergeParams: true });
const taskShareController = require('../controllers/taskShareController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.post('/', taskShareController.shareTask);
router.get('/', taskShareController.getTaskShares);
router.delete('/:shareId', taskShareController.revokeShare);

module.exports = router;