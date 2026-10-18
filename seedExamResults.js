require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Student = require('./models/Student');
const Exam = require('./models/Exam');
const Result = require('./models/Result');

// Grade calculator (same logic as utils/gradeCalculator.js)
const calculateGrade = (percentage) => {
  let grade, gpa;
  if (percentage >= 90) { grade = 'A+'; gpa = 4.0; }
  else if (percentage >= 80) { grade = 'A'; gpa = 3.7; }
  else if (percentage >= 70) { grade = 'B'; gpa = 3.3; }
  else if (percentage >= 60) { grade = 'C'; gpa = 3.0; }
  else if (percentage >= 50) { grade = 'D'; gpa = 2.0; }
  else { grade = 'F'; gpa = 0.0; }
  const status = percentage >= 50 ? 'Pass' : 'Fail';
  return { grade, gpa, status };
};

// Random marks generator (realistic distribution - mostly 40-95 range)
const randomMarks = (totalMarks = 100) => {
  // 70% chance of decent marks (50-95), 30% chance of lower marks (20-55)
  const isGoodStudent = Math.random() > 0.3;
  if (isGoodStudent) {
    return Math.floor(Math.random() * (95 - 50 + 1)) + 50;
  } else {
    return Math.floor(Math.random() * (55 - 20 + 1)) + 20;
  }
};

const SUBJECTS_CONFIG = [
  { subjectName: 'Mathematics', totalMarks: 100, passingMarks: 50 },
  { subjectName: 'English', totalMarks: 100, passingMarks: 50 },
  { subjectName: 'Science', totalMarks: 100, passingMarks: 50 },
  { subjectName: 'Computer Science', totalMarks: 100, passingMarks: 50 },
];

const seedExamsAndResults = async () => {
  await connectDB();
  console.log('🌱 Exam & Result Seeding Started...\n');

  // Optional: Purana exam/result data clean karna chahte hain to uncomment karein
  // await Result.deleteMany({});
  // await Exam.deleteMany({});

  // Step 1: Get distinct class names from Student collection
  const distinctClasses = await Student.distinct('className');
  console.log(`📚 Found ${distinctClasses.length} distinct classes:`, distinctClasses);

  let totalExamsCreated = 0;
  let totalResultsCreated = 0;
  let totalResultsSkipped = 0;

  for (const className of distinctClasses) {
    if (!className) continue; // Skip null/empty className

    // Step 2: Create an exam for this class (Mid Term 2026)
    let exam;
    try {
      exam = await Exam.findOne({ className, examName: 'Mid Term 2026' });
      if (!exam) {
        exam = await Exam.create({
          examName: 'Mid Term 2026',
          examType: 'Midterm',
          className,
          examDate: new Date('2026-03-15'),
          academicYear: '2026',
          subjects: SUBJECTS_CONFIG,
          status: 'Completed',
        });
        totalExamsCreated++;
        console.log(`✅ Exam created for class: ${className}`);
      } else {
        console.log(`ℹ️  Exam already exists for class: ${className}`);
      }
    } catch (err) {
      console.error(`⚠️ Exam creation failed for ${className}:`, err.message);
      continue;
    }

    // Step 3: Get all students in this class
    const students = await Student.find({ className });
    console.log(`   👨‍🎓 Found ${students.length} students in ${className}`);

    // Step 4: Create a result for each student
    for (const student of students) {
      try {
        const existingResult = await Result.findOne({
          examId: exam._id,
          studentId: student._id,
        });

        if (existingResult) {
          totalResultsSkipped++;
          continue;
        }

        // Generate random marks for each subject
        let totalMarksObtained = 0;
        let totalMaxMarks = 0;
        const subjectsWithMarks = SUBJECTS_CONFIG.map((subj) => {
          const marksObtained = randomMarks(subj.totalMarks);
          const subjPercentage = (marksObtained / subj.totalMarks) * 100;
          const { grade } = calculateGrade(subjPercentage);
          totalMarksObtained += marksObtained;
          totalMaxMarks += subj.totalMarks;
          return {
            subjectName: subj.subjectName,
            marksObtained,
            totalMarks: subj.totalMarks,
            grade,
          };
        });

        const percentage = (totalMarksObtained / totalMaxMarks) * 100;
        const { grade: overallGrade, gpa, status } = calculateGrade(percentage);

        await Result.create({
          examId: exam._id,
          studentId: student._id,
          familyId: student.familyId,
          className: exam.className,
          subjects: subjectsWithMarks,
          totalMarksObtained,
          totalMaxMarks,
          percentage: Math.round(percentage * 100) / 100,
          overallGrade,
          gpa,
          status,
          remarks: status === 'Pass' ? 'Good performance' : 'Needs improvement',
        });

        totalResultsCreated++;
      } catch (err) {
        console.error(`   ⚠️ Result creation failed for ${student.fullName}:`, err.message);
      }
    }
  }

  console.log(`\n✅ Seeding Complete!`);
  console.log(`   📝 Exams created: ${totalExamsCreated}`);
  console.log(`   📊 Results created: ${totalResultsCreated}`);
  console.log(`   ⏭️  Results skipped (already existed): ${totalResultsSkipped}`);

  mongoose.connection.close();
};

seedExamsAndResults().catch((err) => {
  console.error('❌ Seeding failed completely:', err);
  mongoose.connection.close();
});