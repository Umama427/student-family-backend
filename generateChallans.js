require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Student = require('./models/Student');
const FeeChallan = require('./models/FeeChallan');

const generateChallans = async () => {
  await connectDB();
  console.log('🧾 Generating challans for all active students...\n');

  const now = new Date();
  const month = now.getMonth() + 1;
  const year = now.getFullYear();
  const dueDate = new Date(year, month - 1, 25);

  const students = await Student.find({ status: 'active' });
  console.log(`Found ${students.length} active students.\n`);

  let created = 0;
  let skipped = 0;
  let failed = 0;

  for (const student of students) {
    try {
      const exists = await FeeChallan.findOne({ studentId: student._id, month, year });
      if (exists) {
        skipped++;
        continue;
      }

      const tuitionFee = student.monthlyTuitionFee || 0;
      const discountPercentage = student.discountPercentage || 0;
      const discountAmount = (tuitionFee * discountPercentage) / 100;
      const totalPayable = tuitionFee - discountAmount;

      await FeeChallan.create({
        studentId: student._id,
        familyId: student.familyId,
        month,
        year,
        tuitionFee,
        discountPercentage,
        discountAmount,
        totalPayable,
        dueDate,
        status: dueDate < now ? 'Overdue' : 'Pending',
        otherCharges: [],
      });

      created++;
    } catch (err) {
      failed++;
      console.error(`⚠️ Failed for student "${student.fullName}":`, err.message);
    }
  }

  console.log(`\n✅ Done!`);
  console.log(`   Created: ${created}`);
  console.log(`   Skipped (already existed): ${skipped}`);
  if (failed > 0) console.log(`   Failed: ${failed}`);

  mongoose.connection.close();
};

generateChallans().catch((err) => {
  console.error('❌ Script failed:', err);
  mongoose.connection.close();
});