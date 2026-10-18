const express = require('express');
const router = express.Router();
const {
  createFamily,
  getFamilies,
  getFamilyById,
  updateFamily,
  deleteFamily,
} = require('../controllers/familyController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect, authorize('admin'));

router.route('/')
  .post(createFamily)
  .get(getFamilies);

router.route('/:id')
  .get(getFamilyById)
  .put(updateFamily)
  .delete(deleteFamily);

module.exports = router;