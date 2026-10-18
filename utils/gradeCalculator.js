/**
 * Calculate grade, GPA and pass/fail status based on percentage
 * @param {Number} percentage
 * @returns {Object} { grade, gpa, status }
 */
const calculateGrade = (percentage) => {
  let grade, gpa, status;

  if (percentage >= 90) {
    grade = 'A+';
    gpa = 4.0;
  } else if (percentage >= 80) {
    grade = 'A';
    gpa = 3.7;
  } else if (percentage >= 70) {
    grade = 'B';
    gpa = 3.3;
  } else if (percentage >= 60) {
    grade = 'C';
    gpa = 3.0;
  } else if (percentage >= 50) {
    grade = 'D';
    gpa = 2.0;
  } else {
    grade = 'F';
    gpa = 0.0;
  }

  status = percentage >= 50 ? 'Pass' : 'Fail';

  return { grade, gpa, status };
};

module.exports = { calculateGrade };