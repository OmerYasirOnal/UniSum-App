
// services/gpaService.js
const { Course, Grade, GradeScale, Term } = require("../models");

async function calculateCourseGPA(courseId) {
    const grades = await Grade.findAll({ where: { course_id: courseId } });
    if (grades.length === 0) return 0;
    const totalWeightedScore = grades.reduce((sum, grade) => sum + (grade.score * (grade.weight / 100)), 0);
    const gradeScales = await GradeScale.findAll({ where: { course_id: courseId } });
    const matchedScale = gradeScales.sort((a, b) => b.min_score - a.min_score).find(scale => totalWeightedScore >= scale.min_score);
    return matchedScale ? matchedScale.gpa : 0;
}

async function calculateTermGPA(termId) {
    const courses = await Course.findAll({ where: { term_id: termId } });
    const totalCredits = courses.reduce((sum, course) => sum + course.credits, 0);
    if (totalCredits === 0) return 0;
    const totalWeightedGPA = courses.reduce((sum, course) => sum + (course.gpa * course.credits), 0);
    return totalWeightedGPA / totalCredits;
}

module.exports = { calculateCourseGPA, calculateTermGPA };

