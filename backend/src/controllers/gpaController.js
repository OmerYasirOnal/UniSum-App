const { Course, GradeScale } = require("../models");

async function calculateGPA(req, res) {
  try {
    const { userId } = req.user;
    const courses = await Course.findAll({ where: { user_id: userId } });

    if (!courses.length) {
      return res.status(200).json({ gpa: 0.0 });
    }

    let totalCredits = 0;
    let totalWeightedGradePoints = 0;

    courses.forEach(course => {
      totalWeightedGradePoints += course.average * course.credits;
      totalCredits += course.credits;
    });

    const gpa = totalCredits > 0 ? (totalWeightedGradePoints / totalCredits) : 0;
    res.status(200).json({ gpa: parseFloat(gpa.toFixed(2)) });
  } catch (error) {
    console.error("Failed to calculate GPA:", error.message);
    res.status(500).json({ message: "Failed to calculate GPA", error: error.message });
  }
}

async function getTermGPA(req, res) {
  try {
    const { termId } = req.params;
    const courses = await Course.findAll({
      where: { term_id: termId },
      attributes: ["id", "credits", "average"],
      include: [{
        model: GradeScale,
        attributes: ["letter", "gpa"],
        where: { is_custom: true },
        required: false
      }]
    });

    if (!courses.length) {
      return res.status(200).json({
        gpa: 0.0,
        totalCredits: 0,
        courseDetails: []
      });
    }

    let totalCredits = 0;
    let totalWeightedGradePoints = 0;
    let courseDetails = [];

    for (const course of courses) {
      const credits = course.credits;
      let gpa = 0;

      // Varsa custom scale’den bak, yoksa default scale’den bak
      if (course.GradeScales && course.GradeScales.length > 0) {
        const scale = course.GradeScales.find(s => s.min_score <= course.average);
        gpa = scale ? scale.gpa : 0;
      } else {
        const defaultScales = [
          { letter: "AA", minScore: 90, gpa: 4.00 },
          { letter: "BA", minScore: 85, gpa: 3.50 },
          { letter: "BB", minScore: 75, gpa: 3.00 },
          { letter: "CB", minScore: 65, gpa: 2.50 },
          { letter: "CC", minScore: 60, gpa: 2.00 },
          { letter: "DC", minScore: 50, gpa: 1.50 },
          { letter: "DD", minScore: 45, gpa: 1.00 },
          { letter: "FD", minScore: 40, gpa: 0.50 },
          { letter: "FF", minScore: 0, gpa: 0.00 }
        ];

        const scale = defaultScales.find(s => s.minScore <= course.average);
        gpa = scale ? scale.gpa : 0;
      }

      totalWeightedGradePoints += gpa * credits;
      totalCredits += credits;

      courseDetails.push({
        courseId: course.id,
        credits,
        average: course.average,
        gpa
      });
    }

    const termGPA = totalCredits > 0 ? (totalWeightedGradePoints / totalCredits) : 0;

    res.status(200).json({
      gpa: parseFloat(termGPA.toFixed(2)),
      totalCredits,
      courseDetails
    });
  } catch (error) {
    console.error("Failed to calculate term GPA:", error.message);
    res.status(500).json({
      message: "Failed to calculate term GPA",
      error: error.message
    });
  }
}

module.exports = { calculateGPA, getTermGPA };