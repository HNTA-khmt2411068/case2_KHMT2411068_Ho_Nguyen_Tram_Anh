const express = require('express');
const router = express.Router();
const taskShareController = require('../controllers/taskShareController');
const { authMiddleware } = require('../middleware/authMiddleware');
const { checkTaskPermission } = require('../middleware/permissionMiddleware');

router.use(authMiddleware);

router.get('/:id/shares', checkTaskPermission('viewer'), taskShareController.getShares);


router.post('/:id/shares', checkTaskPermission('owner'), taskShareController.shareTask);


router.delete('/:id/shares/:shareId', checkTaskPermission('owner'), taskShareController.revokeShare);

module.exports = router;