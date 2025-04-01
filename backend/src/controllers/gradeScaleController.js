const { GradeScale } = require("../models");
const { updateCourseGPA } = require("./courseController");

const logger = {
  info: (msg) => console.info(`[${new Date().toISOString()}] INFO: ${msg}`),
  error: (msg) => console.error(`[${new Date().toISOString()}] ERROR: ${msg}`)
};

async function getGradeScales(req, res) {
  try {
    const { courseId } = req.params;
    const customScales = await GradeScale.findAll({
      where: {
        course_id: courseId,
        is_custom: true
      }
    });
    logger.info(`Grade scales fetched for course ID: ${courseId}`);
    res.status(200).json(customScales);
  } catch (error) {
    logger.error(`Failed to fetch grade scales: ${error.message}`);
    res.status(500).json({ message: "Failed to fetch grade scales", error: error.message });
  }
}

async function saveCustomScales(req, res) {
  try {
    const { courseId } = req.params;
    const { gradeScales } = req.body;

    // 1) Eski custom skalaları sil
    await GradeScale.destroy({
      where: {
        course_id: parseInt(courseId),
        is_custom: true
      }
    });

    // 2) Yeni custom skalaları ekle
    if (gradeScales && gradeScales.length > 0) {
      await GradeScale.bulkCreate(
        gradeScales.map(scale => ({
          course_id: parseInt(courseId),
          letter: scale.letter,
          min_score: scale.min_score,
          gpa: scale.gpa,
          is_custom: true
        }))
      );
    }
    logger.info(`Custom grade scales saved for course ID: ${courseId}`);

    // 3) Dersin GPA'sini yeni eklenen custom skalaya göre yeniden hesapla
    const fakeRes = { status: () => ({ json: () => {} }) }; // Fake response
    await updateCourseGPA({ params: { courseId } }, fakeRes);

    // 4) Kaydedilen custom scale'leri yeniden çek
    const savedScales = await GradeScale.findAll({
      where: {
        course_id: parseInt(courseId),
        is_custom: true
      },
      order: [["min_score", "DESC"]]
    });

    res.status(200).json(savedScales);
  } catch (error) {
    logger.error(`Failed to save grade scales: ${error.message}`);
    res.status(500).json({ message: "Failed to save grade scales", error: error.message });
  }
}

async function deleteCustomScales(req, res) {
  try {
    const { courseId } = req.params;
    await GradeScale.destroy({
      where: {
        course_id: courseId,
        is_custom: true
      }
    });
    logger.info(`Custom grade scales deleted for course ID: ${courseId}`);
    res.status(200).json({ message: "Custom grade scales deleted successfully" });
  } catch (error) {
    logger.error(`Failed to delete grade scales: ${error.message}`);
    res.status(500).json({ message: "Failed to delete grade scales", error: error.message });
  }
}

module.exports = {
  getGradeScales,
  saveCustomScales,
  deleteCustomScales
};