require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Staff = require('./models/Staff');

const assignClasses = async () => {
  await connectDB();

  await Staff.updateOne(
    { fullName: 'Mehran Syed' },
    { $set: { assignedClasses: ['BSCS-1st', 'BSCS-2nd'] } }
  );

  await Staff.updateOne(
    { fullName: 'Jaweria Hameed' },
    { $set: { assignedClasses: ['BSCS-3rd', 'BSCS-4th'] } }
  );

  console.log('✅ Classes assigned to both teachers');
  mongoose.connection.close();
};

assignClasses().catch((err) => {
  console.error('❌ Error:', err);
  mongoose.connection.close();
});