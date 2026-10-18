require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Exam = require('./models/Exam');
const Class = require('./models/Class');
require('./models/Subject'); // required for populate to work

const fixExamSubjects = async () => {
  await connectDB();
  console.log('🔧 Fixing exam subjects using real Class/Subject curriculum...\n');

  const exams = await Exam.find({});
  if (exams.length === 0) {
    console.log('⚠️ No exams found.');
    await mongoose.connection.close();
    return;
  }

  for (const exam of exams) {
    const classDoc = await Class.findOne({ className: exam.className }).populate('subjects');

    if (!classDoc) {
      console.log(`⏭️  Skipping "${exam.examName}" (${exam.className}) — class not found in Class collection.`);
      continue;
    }

    if (!classDoc.subjects || classDoc.subjects.length === 0) {
      console.log(`⚠️  "${exam.examName}" (${exam.className}) — class has no subjects in Subject collection. Skipping.`);
      continue;
    }

    const oldSubjects = (exam.subjects || []).map((s) => s.subjectName).join(', ');

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

    const newSubjectsStr = newSubjects.map((s) => s.subjectName).join(', ');

    console.log(`✅ Fixed "${exam.examName}" (${exam.className})`);
    console.log(`   Before: ${oldSubjects || '(none)'}`);
    console.log(`   After : ${newSubjectsStr}\n`);
  }

  console.log('🎉 Done! All exams now have subjects matching real curriculum.');
  await mongoose.connection.close();
};

fixExamSubjects().catch(async (err) => {
  console.error('❌ Error:', err);
  await mongoose.connection.close();
  process.exit(1);
});