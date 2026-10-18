require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Family = require('./models/Family');
const Staff = require('./models/Staff');

const fixData = async () => {
  await connectDB();

  // ===== FIX 1: Saari families ko default PIN '0000' assign karo jinke paas PIN nahi hai =====
  const familiesWithoutPin = await Family.updateMany(
    { $or: [{ portalPin: { $exists: false } }, { portalPin: null }] },
    { $set: { portalPin: '0000' } }
  );
  console.log(`✅ Fixed ${familiesWithoutPin.modifiedCount} families — default PIN '0000' set`);

  // ===== FIX 2: Teacher designations correct karo =====
  const result1 = await Staff.updateOne(
    { fullName: 'Mehran Syed' },
    { $set: { designation: 'Teacher', department: 'Mobile Application' } }
  );
  const result2 = await Staff.updateOne(
    { fullName: 'Jaweria Hameed' },
    { $set: { designation: 'Teacher', department: 'Machine Learning' } }
  );
  console.log('✅ Fixed designations for Mehran Syed and Jaweria Hameed');

  // ===== FIX 3: Dono teachers ke liye portal access enable karo (test password ke sath) =====
  const Staff2 = require('./models/Staff');

  const mehran = await Staff.findOne({ fullName: 'Mehran Syed' });
  if (mehran) {
    mehran.password = 'teacher123'; // test password - baad mein change kar lena
    mehran.hasPortalAccess = true;
    if (!mehran.email) mehran.email = 'mehran@numl.edu.pk';
    await mehran.save();
    console.log('✅ Mehran Syed portal access enabled');
  }

  const jaweria = await Staff.findOne({ fullName: 'Jaweria Hameed' });
  if (jaweria) {
    jaweria.password = 'teacher123';
    jaweria.hasPortalAccess = true;
    if (!jaweria.email) jaweria.email = 'jaweria@numl.edu.pk';
    await jaweria.save();
    console.log('✅ Jaweria Hameed portal access enabled');
  }

  console.log('\n🎉 All fixes applied successfully!');
  mongoose.connection.close();
};

fixData().catch((err) => {
  console.error('❌ Error:', err);
  mongoose.connection.close();
});