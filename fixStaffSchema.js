require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Staff = require('./models/Staff');

const fixSchema = async () => {
  await connectDB();
  console.log('🔧 Fixing staff schema inconsistencies...\n');

  const allStaff = await Staff.find();
  let fixedCount = 0;

  for (const staff of allStaff) {
    let needsSave = false;

    // Agar phoneNumber field hai lekin phone nahi, to migrate karo
    if (staff.phoneNumber && !staff.phone) {
      staff.phone = staff.phoneNumber;
      needsSave = true;
    }

    // assignedClasses hamesha array honi chahiye
    if (!staff.assignedClasses) {
      staff.assignedClasses = [];
      needsSave = true;
    }

    if (needsSave) {
      await staff.save();
      fixedCount++;
      console.log(`✅ Fixed: ${staff.fullName}`);
    }
  }

  console.log(`\n🎉 Migration complete! ${fixedCount} staff records fixed.`);
  mongoose.connection.close();
};

fixSchema().catch((err) => {
  console.error('❌ Error:', err);
  mongoose.connection.close();
});