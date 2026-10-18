require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Exam = require('./models/Exam');
const Result = require('./models/Result');
const Class = require('./models/Class');
const Staff = require('./models/Staff');
require('./models/Subject'); // required for populate to work

const normalize = (str) => (str || '').trim().toLowerCase();

const sameSet = (arr1, arr2) => {
  const a = new Set(arr1.map(normalize));
  const b = new Set(arr2.map(normalize));
  if (a.size !== b.size) return false;
  for (const item of a) if (!b.has(item)) return false;
  return true;
};

const fixExamsAndResults = async () => {
  console.log('========================================');
  console.log('STEP 1: Fixing corrupt exams + deleting stale results');
  console.log('========================================\n');

  const allClasses = await Class.find({}).populate('subjects');
  const exams = await Exam.find({});

  if (exams.length === 0) {
    console.log('⚠️ No exams found.\n');
    return;
  }

  for (const exam of exams) {
    const classDoc = allClasses.find(
      (c) => normalize(c.className) === normalize(exam.className)
    );

    if (!classDoc) {
      console.log(`⏭️  "${exam.examName}" (${exam.className}) — no matching class found. Skipping.`);
      continue;
    }

    if (!classDoc.subjects || classDoc.subjects.length === 0) {
      console.log(`⚠️  "${exam.examName}" (${exam.className}) — class has no subjects in Subject collection. Skipping.`);
      continue;
    }

    const realSubjectNames = classDoc.subjects.map((s) => s.subjectName);
    const currentSubjectNames = (exam.subjects || []).map((s) => s.subjectName);

    const isCorrupt = !sameSet(realSubjectNames, currentSubjectNames);

    if (!isCorrupt) {
      console.log(`✅ "${exam.examName}" (${exam.className}) — already correct, skipping.\n`);
      continue;
    }

    // Delete stale results tied to this corrupt exam
    const deleteRes = await Result.deleteMany({ examId: exam._id });

    // Rebuild exam.subjects from real curriculum
    const newSubjects = classDoc.subjects.map((subj) => ({
      subjectName: subj.subjectName,
      totalMarks: subj.totalMarks || 100,
      passingMarks: subj.passingMarks || 40,
    }));

    await Exam.findByIdAndUpdate(
      exam._id,
      { subjects: newSubjects },
      { runValidators: false }
    );

    console.log(`🔧 FIXED "${exam.examName}" (${exam.className})`);
    console.log(`   Old subjects : ${currentSubjectNames.join(', ') || '(none)'}`);
    console.log(`   New subjects : ${newSubjects.map((s) => s.subjectName).join(', ')}`);
    console.log(`   🗑️  Deleted ${deleteRes.deletedCount} stale result(s) for this exam — teacher must re-enter marks.\n`);
  }
};

const fixTeacherAssignments = async () => {
  console.log('========================================');
  console.log('STEP 2: Recomputing teacher assignedSubjects (from existing assignedClasses)');
  console.log('========================================\n');

  const allClasses = await Class.find({}).populate('subjects');
  console.log(`📚 Total classes in DB (${allClasses.length}):`);
  allClasses.forEach((c) => console.log(`   - "${c.className}"`));
  console.log('');

  const teachers = await Staff.find({ designation: 'Teacher' });
  if (teachers.length === 0) {
    console.log('⚠️ No teachers found.\n');
    return;
  }

  const coveredClassNames = new Set();

  for (const teacher of teachers) {
    if (!teacher.assignedClasses || teacher.assignedClasses.length === 0) {
      console.log(`⏭️  ${teacher.fullName} — no assignedClasses set. Skipping.\n`);
      continue;
    }

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
    const exactClassNames = matchedClassDocs.map((c) => c.className);

    await Staff.findByIdAndUpdate(
      teacher._id,
      { assignedClasses: exactClassNames, assignedSubjects },
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
    console.log('🚨 These classes have NO teacher assigned at all:');
    uncoveredClasses.forEach((name) => console.log(`   - ${name}`));
    console.log('\n👉 Ye classes manually kisi teacher ko admin panel se (Staff → Assign Classes) dena hoga.\n');
  } else {
    console.log('🎉 All classes have at least one teacher assigned.\n');
  }
};

const run = async () => {
  await connectDB();
  try {
    await fixExamsAndResults();
    await fixTeacherAssignments();
    console.log('========================================');
    console.log('ALL DONE ✅');
    console.log('========================================');
  } catch (err) {
    console.error('❌ Error:', err);
  } finally {
    await mongoose.connection.close();
  }
};

run();