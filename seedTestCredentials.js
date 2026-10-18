require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Staff = require('./models/Staff');
const Family = require('./models/Family');

const setup = async () => {
  await connectDB();
  console.log('🔧 Setting up test credentials...\n');

  // Pehla staff member le kar teacher login enable karein
  const staff = await Staff.findOne();
  if (staff) {
    staff.email = 'teacher@edumanage.com';
    staff.password = 'teacher123'; // auto-hash ho jayega
    staff.assignedClasses = ['BSCS-1st', 'BSCS-2nd'];
    await staff.save();
    console.log(`✅ Teacher credentials set for: ${staff.fullName}`);
    console.log(`   Email: teacher@edumanage.com`);
    console.log(`   Password: teacher123`);
    console.log(`   Assigned Classes: BSCS-1st, BSCS-2nd\n`);
  } else {
    console.log('⚠️ No staff found in database\n');
  }

  // Pehli family le kar parent login enable karein
  const family = await Family.findOne();
  if (family) {
    family.portalPin = '1234';
    await family.save();
    console.log(`✅ Parent credentials set for: ${family.familyName}`);
    console.log(`   Phone: ${family.primaryPhone}`);
    console.log(`   PIN: 1234\n`);
  } else {
    console.log('⚠️ No family found in database\n');
  }

  mongoose.connection.close();
};

setup().catch((err) => {
  console.error('❌ Error:', err);
  mongoose.connection.close();
});