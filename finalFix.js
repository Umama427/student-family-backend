require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Exam = require('./models/Exam');
const Result = require('./models/Result');
const Class = require('./models/Class');
const Staff = require('./models/Staff');
require('./models/Subject');

const normalize = (str) => (str || '').trim().toLowerCase();

const sameSet = (arr1, arr2) => {
  const a = new Set(arr1.map(normalize));
  const b = new Set(arr2.map(normalize));
  if (a.size !== b.size) return false;
  for (const item of a) if (!b.has(item)) return false;
  return true;
};

// STEP 1: Delete orphan/duplicate exams (className doesn't match any real class)
const deleteOrphanExams = async (realClassNames) => {
  console.log('========================================');
  console.log('STEP 1: Deleting orphan/duplicate exams (invalid className)');
  console.log('========================================\n');

  const exams = await Exam.find({});
  let deletedExams = 0;
  let deletedResults = 0;

  for (const exam of exams) {
    const isValid = realClassNames.some((name) => normalize(name) === normalize(exam.className));
    if (!isValid) {
      const resDel = await Result.deleteMany({ examId: exam._id });
      await Exam.findByIdAndDelete(exam._id);
      deletedExams++;
      deletedResults += resDel.deletedCount;
      console.log(`🗑️  Deleted orphan exam "${exam.examName}" (className: "${exam.className}") + ${resDel.deletedCount} result(s)`);
    }
  }

  console.log(`\nTotal orphan exams deleted: ${deletedExams}, total stale results deleted: ${deletedResults}\n`);
};

// STEP 2: Fix exam.subjects for valid-className exams with wrong subjects (deletes their results)
const fixExamSubjects = async (allClasses) => {
  console.log('========================================');
  console.log('STEP 2: Fixing exam subjects (valid classes only)');
  console.log('========================================\n');

  const exams = await Exam.find({});

  for (const exam of exams) {
    const classDoc = allClasses.find((c) => normalize(c.className) === normalize(exam.className));
    if (!classDoc || !classDoc.subjects || classDoc.subjects.length === 0) continue;

    const realSubjectNames = classDoc.subjects.map((s) => s.subjectName);
    const currentSubjectNames = (exam.subjects || []).map((s) => s.subjectName);

    if (sameSet(realSubjectNames, currentSubjectNames)) {
      console.log(`✅ "${exam.examName}" (${exam.className}) — subjects already correct.`);
      continue;
    }

    const delRes = await Result.deleteMany({ examId: exam._id });

    const newSubjects = classDoc.subjects.map((subj) => ({
      subjectName: subj.subjectName,
      totalMarks: subj.totalMarks || 100,
      passingMarks: subj.passingMarks || 40,
    }));

    await Exam.findByIdAndUpdate(exam._id, { subjects: newSubjects }, { runValidators: false });

    console.log(`🔧 FIXED "${exam.examName}" (${exam.className})`);
    console.log(`   Old: ${currentSubjectNames.join(', ') || '(none)'}`);
    console.log(`   New: ${newSubjects.map((s) => s.subjectName).join(', ')}`);
    console.log(`   🗑️  Deleted ${delRes.deletedCount} stale result(s).\n`);
  }
};

// STEP 3: Delete leftover Result docs whose subjects don't match exam's CURRENT subjects
// (fixes case where exam was already fixed earlier, but old results from before that fix still exist)
const cleanupStaleResults = async () => {
  console.log('========================================');
  console.log('STEP 3: Cleaning up stale results (leftover from previously-fixed exams)');
  console.log('========================================\n');

  const exams = await Exam.find({});
  let totalDeleted = 0;

  for (const exam of exams) {
    const realSubjectNames = (exam.subjects || []).map((s) => s.subjectName);
    if (realSubjectNames.length === 0) continue;

    const results = await Result.find({ examId: exam._id });

    for (const result of results) {
      const resultSubjectNames = (result.subjects || []).map((s) => s.subjectName);
      if (!sameSet(realSubjectNames, resultSubjectNames)) {
        await Result.findByIdAndDelete(result._id);
        totalDeleted++;
        console.log(`🗑️  Deleted stale result (studentId: ${result.studentId}) for exam "${exam.examName}" — had [${resultSubjectNames.join(', ')}] but exam now has [${realSubjectNames.join(', ')}]`);
      }
    }
  }

  console.log(`\nTotal stale results deleted: ${totalDeleted}\n`);
};

// STEP 4: Recompute assignedSubjects for existing teachers
const fixExistingTeachers = async (allClasses) => {
  console.log('========================================');
  console.log('STEP 4: Recomputing assignedSubjects for existing teachers');
  console.log('========================================\n');

  const teachers = await Staff.find({ designation: 'Teacher' });
  const coveredClassNames = new Set();

  for (const teacher of teachers) {
    if (!teacher.assignedClasses || teacher.assignedClasses.length === 0) {
      console.log(`⏭️  ${teacher.fullName} — no assignedClasses. Skipping.\n`);
      continue;
    }

    const matchedClassDocs = allClasses.filter((c) =>
      teacher.assignedClasses.some((name) => normalize(name) === normalize(c.className))
    );
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
    console.log(`   Classes : ${exactClassNames.join(', ')}`);
    console.log(`   Subjects: ${assignedSubjects.join(', ') || '(none found)'}\n`);
  }

  return coveredClassNames;
};

// STEP 5: Create new teachers for uncovered classes (BSCS-5,6,7,8 etc.)
const createTeachersForUncoveredClasses = async (allClasses, coveredClassNames) => {
  console.log('========================================');
  console.log('STEP 5: Creating new teachers for uncovered classes');
  console.log('========================================\n');

  const uncovered = allClasses
    .map((c) => c.className)
    .filter((name) => !coveredClassNames.has(name));

  if (uncovered.length === 0) {
    console.log('🎉 All classes already have a teacher. No new teachers needed.\n');
    return;
  }

  console.log(`Classes needing teachers: ${uncovered.join(', ')}\n`);

  // Group uncovered classes, 2 per new teacher
  const newTeacherDefs = [];
  for (let i = 0; i < uncovered.length; i += 2) {
    newTeacherDefs.push(uncovered.slice(i, i + 2));
  }

  const sampleNames = ['Ali Raza', 'Sana Khan', 'Bilal Ahmed', 'Hira Noor', 'Usman Tariq', 'Mariam Fatima'];
  const createdCredentials = [];

  for (let i = 0; i < newTeacherDefs.length; i++) {
    const classGroup = newTeacherDefs[i];
    const fullName = sampleNames[i] || `New Teacher ${i + 1}`;
    const emailSlug = fullName.toLowerCase().replace(/\s+/g, '.');
    const email = `${emailSlug}@edumanage.com`;
    const phone = `030000${(10000 + i).toString().slice(-5)}`;
    const password = 'Teacher@123';

    const classDocs = allClasses.filter((c) => classGroup.includes(c.className));
    const subjectNames = new Set();
    classDocs.forEach((cls) => (cls.subjects || []).forEach((s) => s && subjectNames.add(s.subjectName)));
    const assignedSubjects = Array.from(subjectNames);

    const existing = await Staff.findOne({ email });
    if (existing) {
      await Staff.findByIdAndUpdate(existing._id, {
        assignedClasses: classGroup,
        assignedSubjects,
      }, { runValidators: false });
      console.log(`⏭️  ${fullName} (${email}) already existed — updated assignments only.\n`);
      continue;
    }

    const newTeacher = await Staff.create({
      fullName,
      email,
      phone,
      department: 'Computer Science',
      designation: 'Teacher',
      basicSalary: 50000,
      status: 'active',
      password,
      hasPortalAccess: true,
      assignedClasses: classGroup,
      assignedSubjects,
    });

    createdCredentials.push({ fullName, email, password, classes: classGroup });

    console.log(`✅ Created teacher: ${fullName} (${newTeacher.staffCode})`);
    console.log(`   Email   : ${email}`);
    console.log(`   Password: ${password}`);
    console.log(`   Classes : ${classGroup.join(', ')}`);
    console.log(`   Subjects: ${assignedSubjects.join(', ') || '(none found)'}\n`);
  }

  if (createdCredentials.length > 0) {
    console.log('📋 LOGIN CREDENTIALS FOR NEW TEACHERS (save karein!):');
    createdCredentials.forEach((t) => {
      console.log(`   ${t.fullName} → email: ${t.email} | password: ${t.password} | classes: ${t.classes.join(', ')}`);
    });
    console.log('');
  }
};

const run = async () => {
  await connectDB();
  try {
    const allClasses = await Class.find({}).populate('subjects');
    const realClassNames = allClasses.map((c) => c.className);

    await deleteOrphanExams(realClassNames);
    await fixExamSubjects(allClasses);
    await cleanupStaleResults();
    const covered = await fixExistingTeachers(allClasses);
    await createTeachersForUncoveredClasses(allClasses, covered);

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