require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Staff = require('./models/Staff');
const Class = require('./models/Class');
require('./models/Subject'); // ✅ Subject model register karna zaroori hai for populate

const seedAssignTeachers = async () => {
  await connectDB();
  console.log('👨‍🏫 Assigning subjects to teachers based on their assigned classes...\n');

  const teachers = await Staff.find({ designation: 'Teacher' });

  if (teachers.length === 0) {
    console.log('⚠️ No teachers found in Staff collection.');
    await mongoose.connection.close();
    return;
  }

  for (const teacher of teachers) {
    if (!teacher.phone) {
      console.log(`⚠️  Warning: ${teacher.fullName} (${teacher.staffCode}) has no 'phone' field set — old/incomplete record. Continuing anyway...`);
    }

    if (!teacher.assignedClasses || teacher.assignedClasses.length === 0) {
      console.log(`⏭️  Skipping ${teacher.fullName} — no assignedClasses set. (Assign classes first via Admin Panel)`);
      continue;
    }

    const classDocs = await Class.find({ className: { $in: teacher.assignedClasses } }).populate('subjects');

    const subjectNames = new Set();
    classDocs.forEach((cls) => {
      (cls.subjects || []).forEach((subj) => {
        if (subj && subj.subjectName) subjectNames.add(subj.subjectName);
      });
    });

    const assignedSubjects = Array.from(subjectNames);

    // ✅ FIX: findByIdAndUpdate use kiya instead of teacher.save()
    // taake poore document ki validation na ho (purane records mein 'phone'
    // missing hone ki wajah se .save() fail ho raha tha)
    await Staff.findByIdAndUpdate(
      teacher._id,
      { assignedSubjects },
      { runValidators: false }
    );

    console.log(`✅ ${teacher.fullName} (${teacher.email})`);
    console.log(`   Classes : ${teacher.assignedClasses.join(', ')}`);
    console.log(`   Subjects: ${assignedSubjects.join(', ') || '(none found)'}\n`);
  }

  console.log('🎉 Done! All teachers now have subjects assigned based on their classes.');
  await mongoose.connection.close();
};

seedAssignTeachers().catch(async (err) => {
  console.error('❌ Error:', err);
  await mongoose.connection.close();
  process.exit(1);
});