require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Student = require('./models/Student');
const Family = require('./models/Family');
const FeeChallan = require('./models/FeeChallan');

const checkData = async () => {
  await connectDB();

  const studentCount = await Student.countDocuments();
  const familyCount = await Family.countDocuments();
  const challanCount = await FeeChallan.countDocuments();
  const activeStudentCount = await Student.countDocuments({ status: 'active' });

  console.log('\n📊 ===== DATABASE SUMMARY =====');
  console.log(`   Total Students: ${studentCount}`);
  console.log(`   Active Students: ${activeStudentCount}`);
  console.log(`   Total Families: ${familyCount}`);
  console.log(`   Total Challans: ${challanCount}`);
  console.log('================================\n');

  // OLDEST 5 students (first created - likely your manual test data)
  const oldestStudents = await Student.find().sort({ createdAt: 1 }).limit(5).select('fullName className status createdAt');
  console.log('👥 OLDEST 5 Students (first created):');
  oldestStudents.forEach((s) => console.log(`   - ${s.fullName} | ${s.className} | ${s.status} | ${s.createdAt}`));

  // NEWEST 5 students (last created - should be from seed.js if it ran)
  const newestStudents = await Student.find().sort({ createdAt: -1 }).limit(5).select('fullName className status createdAt');
  console.log('\n🆕 NEWEST 5 Students (last created):');
  newestStudents.forEach((s) => console.log(`   - ${s.fullName} | ${s.className} | ${s.status} | ${s.createdAt}`));

  // Count students by className to see if seeded semesters exist
  const classGroups = await Student.aggregate([
    { $group: { _id: '$className', count: { $sum: 1 } } },
    { $sort: { _id: 1 } },
  ]);
  console.log('\n📚 Students Grouped by Class/Semester:');
  classGroups.forEach((g) => console.log(`   - ${g._id || 'N/A'}: ${g.count} students`));

  mongoose.connection.close();
};

checkData().catch((err) => {
  console.error('❌ Error:', err);
  mongoose.connection.close();
});