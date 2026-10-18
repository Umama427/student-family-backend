require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Class = require('./models/Class');
const Subject = require('./models/Subject');

const classSubjectData = {
  'BSCS-1st': ['Maths-I', 'Applied Physics', 'App. Info. & Com. Tech', 'Functional English', 'Pakistan Studies', 'Islamic Studies', 'Programming Fundamentals'],
  'BSCS-2nd': ['Pre-Maths-II', 'Object Oriented Programming', 'Calculus and Analytical Geometry', 'Expository Writing', 'Discrete Structures', 'Ideology and Constitution of Pakistan', 'Civics and Community Engagement'],
  'BSCS-3rd': ['Digital Logic Design', 'Data Structures', 'Linear Algebra', 'Digital Marketing', 'Database Systems', 'Technology Entrepreneurship'],
  'BSCS-4th': ['Artificial Intelligence', 'Software Engineering', 'Web Technology', 'Advance Programming', 'Professional Practices', 'Computer Organization and Assembly Languages'],
  'BSCS-5th': ['Web Engineering', 'Computer Architecture', 'Statistics And Probability', 'Theory of Automata', 'Operating System', 'Multivariable Calculus'],
  'BSCS-6th': ['Analysis of Algorithms', 'Computer Networks', 'Advance Database Management System', 'Machine Learning', 'Technical And Business Writing', 'Mobile Application Development'],
  'BSCS-7th': ['Computer Graphics', 'Software Project Management', 'Compiler Construction', 'Foreign Language', 'Information Security', 'Final Year Project – I'],
  'BSCS-8th': ['Parallel And Distributed Computing', 'Economics for Computing', 'Final Year Project – II'],
};

const seedClassesAndSubjects = async () => {
  await connectDB();
  console.log('🏫 Seeding classes and subjects...\n');

  let classCount = 0;
  let subjectCount = 0;

  for (const [className, subjects] of Object.entries(classSubjectData)) {
    let cls = await Class.findOne({ className });

    if (!cls) {
      cls = await Class.create({ className, section: 'Morning', subjects: [] });
      classCount++;
      console.log(`✅ Created class: ${className}`);
    } else {
      console.log(`⏭️  Class already exists: ${className}`);
      if (!cls.subjects) cls.subjects = [];
    }

    for (const subjectName of subjects) {
      // ✅ updated field name: "class" instead of "classId"
      const exists = await Subject.findOne({ subjectName, class: cls._id });
      if (exists) continue;

      const subject = await Subject.create({
        subjectName,
        class: cls._id,        // ✅ matches schema field
        creditHours: 3,
        totalMarks: 100,
        passingMarks: 40,
      });

      cls.subjects.push(subject._id);
      subjectCount++;
      console.log(`   ➕ Added subject: ${subjectName} (${className})`);
    }

    await cls.save();
  }

  console.log(`\n✅ Done!`);
  console.log(`   Classes created: ${classCount}`);
  console.log(`   Subjects created: ${subjectCount}`);

  await mongoose.connection.close();
};

seedClassesAndSubjects().catch(async (err) => {
  console.error('❌ Error:', err);
  await mongoose.connection.close();
  process.exit(1);
});