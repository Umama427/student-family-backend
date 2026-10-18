require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Student = require('./models/Student');
require('./models/Family'); // ✅ YEH LINE ADD KAREIN (populate ke liye zaroori)

const ODD_CLASSES = ['10', '12', '1st', '2nd', '3rd', '5th', '9'];

const inspect = async () => {
  await connectDB();
  console.log('🔍 Inspecting students with odd className values...\n');

  for (const className of ODD_CLASSES) {
    const students = await Student.find({ className }).populate(
      'familyId',
      'familyName primaryPhone'
    );

    console.log(`\n📌 Class: "${className}" — ${students.length} student(s)`);
    students.forEach((s) => {
      console.log(
        `   - ID: ${s._id} | Name: ${s.fullName} | Family: ${
          s.familyId?.familyName || 'N/A'
        } | Created: ${s.createdAt}`
      );
    });
  }

  mongoose.connection.close();
};

inspect().catch((err) => {
  console.error('❌ Error:', err);
  mongoose.connection.close();
});