require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Staff = require('./models/Staff');
const Class = require('./models/Class');
require('./models/Subject');

const normalize = (str) => (str || '').trim().toLowerCase();

const fixTeacherAssignments = async () => {
  await connectDB();
  console.log('🔧 Recomputing assignedSubjects from EXISTING assignedClasses (no hardcoding)...\n');

  const allClasses = await Class.find({}).populate('subjects');
  console.log(`📚 Total classes in DB (${allClasses.length}):`);
  allClasses.forEach((c) => console.log(`   - "${c.className}"`));
  console.log('');

  const teachers = await Staff.find({ designation: 'Teacher' });
  if (teachers.length === 0) {
    console.log('⚠️ No teachers found.');
    await mongoose.connection.close();
    return;
  }

  console.log(`👨‍🏫 Total teachers in DB: ${teachers.length}\n`);

  const coveredClassNames = new Set();

  for (const teacher of teachers) {
    if (!teacher.assignedClasses || teacher.assignedClasses.length === 0) {
      console.log(`⏭️  ${teacher.fullName} — no assignedClasses set. Skipping.`);
      continue;
    }

    // Match teacher's assignedClasses (whatever strings are stored) against real Class docs,
    // using normalized (trim + lowercase) comparison to catch casing/spacing mismatches.
    const matchedClassDocs = allClasses.filter((c) =>
      teacher.assignedClasses.some((name) => normalize(name) === normalize(c.className))
    );

    const unmatched = teacher.assignedClasses.filter(
      (name) => !allClasses.some((c) => normalize(c.className) === normalize(name))
    );

    if (unmatched.length > 0) {
      console.log(`⚠️  ${teacher.fullName} — these assignedClasses values DON'T match any real class: [${unmatched.join(', ')}]`);
    }

    matchedClassDocs.forEach((c) => coveredClassNames.add(c.className));

    const subjectNames = new Set();
    matchedClassDocs.forEach((cls) => {
      (cls.subjects || []).forEach((subj) => {
        if (subj && subj.subjectName) subjectNames.add(subj.subjectName);
      });
    });
    const assignedSubjects = Array.from(subjectNames);

    // Also normalize assignedClasses itself to the EXACT real className (fixes casing issues)
    const exactClassNames = matchedClassDocs.map((c) => c.className);

    await Staff.findByIdAndUpdate(
      teacher._id,
      {
        assignedClasses: exactClassNames,
        assignedSubjects: assignedSubjects,
      },
      { runValidators: false }
    );

    console.log(`✅ ${teacher.fullName} (${teacher.email || teacher.staffCode})`);
    console.log(`   Classes : ${exactClassNames.join(', ') || '(none matched)'}`);
    console.log(`   Subjects: ${assignedSubjects.join(', ') || '(none found)'}\n`);
  }

  const uncoveredClasses = allClasses
    .map((c) => c.className)
    .filter((name) => !coveredClassNames.has(name));

  if (uncoveredClasses.length > 0) {
    console.log('🚨 NOTE: These classes have NO teacher assigned at all:');
    uncoveredClasses.forEach((name) => console.log(`   - ${name}`));
    console.log('\n👉 Inhe kisi teacher ko manually admin panel se (Staff → Assign Classes) assign karna hoga — script khud decide nahi kar sakti ke kis teacher ko dena hai.\n');
  }

  console.log('🎉 Done.');
  await mongoose.connection.close();
};

fixTeacherAssignments().catch(async (err) => {
  console.error('❌ Error:', err);
  await mongoose.connection.close();
  process.exit(1);
});