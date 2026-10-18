require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Salary = require('./models/Salary');
const Staff = require('./models/Staff');

const verifySalaries = async () => {
  await connectDB();

  const allSalaries = await Salary.find().lean();
  const allStaffIds = (await Staff.find().select('_id fullName').lean()).map(s => ({
    id: s._id.toString(),
    name: s.fullName,
  }));

  console.log('\n💰 ===== SALARY VERIFICATION REPORT =====');
  console.log(`Total Salary Records: ${allSalaries.length}`);
  console.log(`Total Staff Members: ${allStaffIds.length}\n`);

  let validCount = 0;
  let invalidCount = 0;
  let missingCount = 0;
  const invalidRecords = [];

  for (const sal of allSalaries) {
    if (!sal.staffId) {
      missingCount++;
      invalidRecords.push({ _id: sal._id, issue: 'staffId is NULL/missing', month: sal.month, year: sal.year });
      continue;
    }

    const staffIdStr = sal.staffId.toString();
    const matchedStaff = allStaffIds.find(s => s.id === staffIdStr);

    if (matchedStaff) {
      validCount++;
    } else {
      invalidCount++;
      invalidRecords.push({
        _id: sal._id,
        issue: `staffId (${staffIdStr}) does not match any existing Staff record`,
        month: sal.month,
        year: sal.year,
        netSalary: sal.netSalary,
      });
    }
  }

  console.log(`✅ Valid (staffId matches real staff): ${validCount}`);
  console.log(`❌ Invalid (staffId points to non-existent staff): ${invalidCount}`);
  console.log(`⚠️  Missing (staffId is null/undefined): ${missingCount}`);

  if (invalidRecords.length > 0) {
    console.log('\n📋 Problematic Records:');
    invalidRecords.forEach((r, i) => {
      console.log(`${i + 1}. ID: ${r._id} | ${r.issue} | Month/Year: ${r.month}/${r.year} | Net: ${r.netSalary || 'N/A'}`);
    });
  } else {
    console.log('\n🎉 All salary records are properly linked!');
  }

  console.log('==========================================\n');

  mongoose.connection.close();
};

verifySalaries().catch((err) => {
  console.error('Error:', err);
  mongoose.connection.close();
});