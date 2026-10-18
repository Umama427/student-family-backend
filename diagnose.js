require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Staff = require('./models/Staff');
const Family = require('./models/Family');
const Student = require('./models/Student');

const diagnose = async () => {
  await connectDB();

  console.log('\n👨‍🏫 ===== STAFF DIAGNOSIS =====');
  const totalStaff = await Staff.countDocuments();
  console.log(`Total Staff Documents: ${totalStaff}`);

  const allStaff = await Staff.find().select('fullName designation status hasPortalAccess email');
  allStaff.forEach((s) => {
    console.log(`   - ${s.fullName} | Designation: ${s.designation} | Status: ${s.status} | PortalAccess: ${s.hasPortalAccess} | Email: ${s.email}`);
  });

  console.log('\n👪 ===== FAMILY DIAGNOSIS =====');
  const totalFamilies = await Family.countDocuments();
  console.log(`Total Family Documents: ${totalFamilies}`);

  // Check kitni families ke paas actual linked students hain
  const familiesWithStudents = await Family.aggregate([
    {
      $lookup: {
        from: 'students',
        localField: '_id',
        foreignField: 'familyId',
        as: 'linkedStudents',
      },
    },
    {
      $project: {
        familyName: 1,
        primaryPhone: 1,
        portalPin: 1,
        studentCount: { $size: '$linkedStudents' },
      },
    },
  ]);

  const familiesWithZeroStudents = familiesWithStudents.filter((f) => f.studentCount === 0);
  const familiesWithStudentsCount = familiesWithStudents.filter((f) => f.studentCount > 0);

  console.log(`Families WITH linked students: ${familiesWithStudentsCount.length}`);
  console.log(`Families WITHOUT any linked students: ${familiesWithZeroStudents.length}`);

  console.log('\nFirst 10 families with their student counts:');
  familiesWithStudents.slice(0, 10).forEach((f) => {
    console.log(`   - ${f.familyName} | Phone: ${f.primaryPhone} | PIN: ${f.portalPin} | Students: ${f.studentCount}`);
  });

  // Check duplicate primaryPhone (login issue ka reason ho sakta hai)
  const phoneGroups = await Family.aggregate([
    { $group: { _id: '$primaryPhone', count: { $sum: 1 } } },
    { $match: { count: { $gt: 1 } } },
  ]);
  console.log(`\n⚠️ Duplicate Phone Numbers Found: ${phoneGroups.length}`);
  phoneGroups.forEach((p) => console.log(`   - Phone: ${p._id} appears ${p.count} times`));

  console.log('\n👶 ===== STUDENT -> FAMILY LINK CHECK =====');
  const totalStudents = await Student.countDocuments();
  const studentsWithValidFamilyId = await Student.countDocuments({ familyId: { $ne: null } });
  console.log(`Total Students: ${totalStudents}`);
  console.log(`Students with a familyId set: ${studentsWithValidFamilyId}`);
  console.log(`Students WITHOUT familyId (orphaned): ${totalStudents - studentsWithValidFamilyId}`);

  mongoose.connection.close();
};

diagnose().catch((err) => {
  console.error('❌ Error:', err);
  mongoose.connection.close();
});