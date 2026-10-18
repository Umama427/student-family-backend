require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Student = require('./models/Student');

const randomPhone = () =>
  `03${Math.floor(100000000 + Math.random() * 899999999)}`.slice(0, 11);

const seedStudentContacts = async () => {
  await connectDB();
  console.log('📱 Seeding contact numbers for students missing one...\n');

  const students = await Student.find({
    $or: [
      { contactNumber: null },
      { contactNumber: '' },
      { contactNumber: { $exists: false } },
    ],
  });

  if (students.length === 0) {
    console.log('🎉 All students already have a contact number. Nothing to do.');
    await mongoose.connection.close();
    return;
  }

  console.log(`Found ${students.length} student(s) without a contact number.\n`);

  let updated = 0;
  for (const student of students) {
    const contactNumber = randomPhone();
    await Student.findByIdAndUpdate(
      student._id,
      { contactNumber },
      { runValidators: false }
    );
    updated++;
    console.log(`✅ ${student.fullName} (${student.rollNumber}) → ${contactNumber}`);
  }

  console.log(`\n🎉 Done! ${updated} student(s) updated with a contact number.`);
  console.log('ℹ️  Field optional hi rahega — future students bina number ke bhi add ho sakte hain (null allowed, koi error nahi aayega).');
  await mongoose.connection.close();
};

seedStudentContacts().catch(async (err) => {
  console.error('❌ Error:', err);
  await mongoose.connection.close();
  process.exit(1);
});