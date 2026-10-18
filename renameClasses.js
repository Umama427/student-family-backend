require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Student = require('./models/Student');

// Purana naam -> Naya sahi naam (BSCS format ke mutabiq)
const RENAME_MAP = {
  '1st': 'BSCS-1st',
  '2nd': 'BSCS-2nd',
  '3rd': 'BSCS-3rd',
  '5th': 'BSCS-5th',
  '9': 'BSCS-9th',
  '10': 'BSCS-10th',
  '12': 'BSCS-12th',
};

const rename = async () => {
  await connectDB();
  console.log('✏️  Renaming classes...\n');

  let totalUpdated = 0;

  for (const [oldName, newName] of Object.entries(RENAME_MAP)) {
    const result = await Student.updateMany(
      { className: oldName },
      { $set: { className: newName } }
    );
    console.log(`✅ "${oldName}" → "${newName}": ${result.modifiedCount} student(s) updated`);
    totalUpdated += result.modifiedCount;
  }

  console.log(`\n🎉 Total students renamed: ${totalUpdated}`);

  mongoose.connection.close();
};

rename().catch((err) => {
  console.error('❌ Error:', err);
  mongoose.connection.close();
});