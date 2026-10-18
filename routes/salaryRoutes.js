const express = require('express');
const router = express.Router();
const {
  generateSalary,
  getSalaries,
  getSalaryById,
  deleteSalary,
} = require('../controllers/salaryController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect, authorize('admin'));

router.get('/', getSalaries);
router.post('/', generateSalary);
router.get('/:id', getSalaryById);
router.delete('/:id', deleteSalary);

module.exports = router;