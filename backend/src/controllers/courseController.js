const { Course, GradeScale, Grade } = require("../models");
const { updateTermGPA } = require("./termController");

// Basit logger yardımcı fonksiyonu
const logger = {
  info: (msg) => console.info(`[${new Date().toISOString()}] INFO: ${msg}`),
  error: (msg) => console.error(`[${new Date().toISOString()}] ERROR: ${msg}`)
};

async function createCourse(req, res) {
  try {
    const { term_id, user_id, name, credits } = req.body;

    if (!name) {
      logger.error("Create Course: Course name is required.");
      return res.status(400).json({ message: "Course name is required." });
    }

    const newCourse = await Course.create({ term_id, user_id, name, credits });
    logger.info(`Course created. ID: ${newCourse.id}`);

    return res.status(201).json({
      id: newCourse.id,
      term_id: newCourse.term_id,
      user_id: newCourse.user_id,
      name: newCourse.name,
      credits: newCourse.credits,
      average: newCourse.average,
      createdAt: newCourse.createdAt,
      updatedAt: newCourse.updatedAt
    });
  } catch (error) {
    logger.error(`Failed to create course: ${error.message}`);
    res.status(500).json({ message: "Failed to create course", error: error.message });
  }
}

async function getCoursesByTerm(req, res) {
  try {
    const { termId } = req.params;

    if (!termId) {
      logger.error("Get Courses: Term ID is required.");
      return res.status(400).json({ message: "Term ID is required" });
    }

    const courses = await Course.findAll({
      where: { term_id: termId },
      order: [["createdAt", "ASC"]]
    });
    logger.info(`Fetched courses for term ID: ${termId}`);

    return res.status(200).json(courses);
  } catch (error) {
    logger.error(`Failed to fetch courses: ${error.message}`);
    return res.status(500).json({
      message: "Failed to fetch courses",
      error: error.message
    });
  }
}

async function deleteCourse(req, res) {
  try {
    const { courseId } = req.params;
    await Grade.destroy({ where: { course_id: courseId } });
    await Course.destroy({ where: { id: courseId } });
    logger.info(`Course and related grades deleted. Course ID: ${courseId}`);
    return res.status(200).json({ message: "Course and related grades deleted successfully." });
  } catch (error) {
    logger.error(`Failed to delete course: ${error.message}`);
    res.status(500).json({ message: "Failed to delete course", error: error.message });
  }
}

async function updateCourseAverage(req, res) {
  try {
    const { courseId } = req.params;
    const { average } = req.body;

    const course = await Course.findByPk(courseId);
    if (!course) {
      logger.error(`Update Course Average: Course not found. ID: ${courseId}`);
      return res.status(404).json({ message: "Course not found" });
    }

    await course.update({ average });
    logger.info(`Course average updated. ID: ${courseId}, New Average: ${average}`);
    res.status(200).json(course);
  } catch (error) {
    logger.error(`Failed to update course average: ${error.message}`);
    res.status(500).json({
      message: "Failed to update course average",
      error: error.message
    });
  }
}

async function updateCourseGPA(req, res) {
  try {
    const { courseId } = req.params;
    const course = await Course.findByPk(courseId);
    if (!course) {
      logger.error(`Update Course GPA: Course not found. ID: ${courseId}`);
      return res.status(404).json({ message: "Course not found" });
    }

    // 1) Custom scale (is_custom=true)
    let gradeScales = await GradeScale.findAll({
      where: { course_id: courseId, is_custom: true },
      order: [["min_score", "DESC"]]
    });

    // 2) Default scale
    const defaultScales = [
      { letter: "AA", min_score: 90, gpa: 4.0 },
      { letter: "BA", min_score: 85, gpa: 3.5 },
      { letter: "BB", min_score: 75, gpa: 3.0 },
      { letter: "CB", min_score: 65, gpa: 2.5 },
      { letter: "CC", min_score: 60, gpa: 2.0 },
      { letter: "DC", min_score: 50, gpa: 1.5 },
      { letter: "DD", min_score: 45, gpa: 1.0 },
      { letter: "FD", min_score: 40, gpa: 0.5 },
      { letter: "FF", min_score: 0,  gpa: 0.0 }
    ];

    // 3) Merge default + custom
    let mergedScales = [...defaultScales];
    for (let i = 0; i < mergedScales.length; i++) {
      const letter = mergedScales[i].letter;
      const override = gradeScales.find(c => c.letter === letter);
      if (override) {
        mergedScales[i].min_score = override.min_score;
        mergedScales[i].gpa = override.gpa;
      }
    }
    mergedScales.sort((a, b) => b.min_score - a.min_score);

    // 4) Dersin ortalamasına uygun harf notunu bul
    let newGPA = 0.0;
    let letterGrade = "FF";
    for (const scale of mergedScales) {
      if (course.average >= scale.min_score) {
        letterGrade = scale.letter;
        newGPA = scale.gpa;
        break;
      }
    }

    // 5) Veritabanında dersin gpa ve letterGrade güncelle
    await course.update({ gpa: newGPA, letterGrade });
    logger.info(`Course GPA updated. Course ID: ${courseId}, GPA: ${newGPA}, Letter Grade: ${letterGrade}`);

    // 6) JSON döndür
    return res.status(200).json({
      courseId: parseInt(courseId),
      gpa: newGPA,
      letterGrade
    });
  } catch (error) {
    logger.error(`Failed to update course GPA: ${error.message}`);
    return res.status(500).json({ message: "Failed to update course GPA", error: error.message });
  }
}

async function updateAllCoursesGPAByTerm(req, res) {
  try {
    const { termId } = req.params;
    const courses = await Course.findAll({ where: { term_id: termId } });

    if (!courses.length) {
      logger.error(`Update All Courses GPA: No courses found for term ID: ${termId}`);
      return res.status(404).json({ message: "Bu döneme ait ders bulunamadı." });
    }

    // Tüm dersler için GPA güncellemesi
    await Promise.all(
      courses.map(course =>
        updateCourseGPA({ params: { courseId: course.id } }, { status: () => ({ json: () => {} }) })
      )
    );

    // Dönemin GPA’sini güncelle
    await updateTermGPA({ params: { termId } }, res);
    logger.info(`All courses GPA updated for term ID: ${termId}`);

    res.status(200).json({ message: "Tüm derslerin ve dönemin GPA'sı güncellendi." });
  } catch (error) {
    logger.error(`Error updating all courses GPA: ${error.message}`);
    res.status(500).json({ message: "Derslerin GPA'sı güncellenirken hata oluştu.", error: error.message });
  }
}

module.exports = {
  createCourse,
  getCoursesByTerm,
  deleteCourse,
  updateCourseAverage,
  updateCourseGPA,
  updateAllCoursesGPAByTerm
};