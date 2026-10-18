require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Class = require('./models/Class');
const Staff = require('./models/Staff');

const normalize = (str) => (str || '').trim().toLowerCase();

const syncClassTeachers = async () => {
  await connectDB();
  console.log('🔧 Syncing Class.classTeacher from Staff.assignedClasses...\n');

  const allClasses = await Class.find({});
  const teachers = await Staff.find({ designation: 'Teacher' });

  if (allClasses.length === 0) {
    console.log('⚠️ No classes found.');
    await mongoose.connection.close();
    return;
  }

  for (const cls of allClasses) {
    // Find teacher(s) whose assignedClasses includes this class (normalized match)
    const matchedTeachers = teachers.filter((t) =>
      (t.assignedClasses || []).some((name) => normalize(name) === normalize(cls.className))
    );

    if (matchedTeachers.length === 0) {
      console.log(`⏭️  "${cls.className}" — no teacher has this class assigned. Leaving classTeacher as-is.`);
      continue;
    }

    if (matchedTeachers.length > 1) {
      console.log(`⚠️  "${cls.className}" — MULTIPLE teachers have this class assigned: ${matchedTeachers.map((t) => t.fullName).join(', ')}. Using the first one: ${matchedTeachers[0].fullName}.`);
    }

    const chosenTeacher = matchedTeachers[0];

    await Class.findByIdAndUpdate(
      cls._id,
      { classTeacher: chosenTeacher._id },
      { runValidators: false }
    );

    console.log(`✅ "${cls.className}" → Class Teacher set to: ${chosenTeacher.fullName}`);
  }

  console.log('\n🎉 Done! Refresh the admin Classes screen now.');
  await mongoose.connection.close();
};

syncClassTeachers().catch(async (err) => {
  console.error('❌ Error:', err);
  await mongoose.connection.close();
  process.exit(1);
});