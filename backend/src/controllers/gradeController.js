const { Grade } = require("../models");

const logger = {
  info: (msg) => console.info(`[${new Date().toISOString()}] INFO: ${msg}`),
  error: (msg) => console.error(`[${new Date().toISOString()}] ERROR: ${msg}`)
};

async function addGrade(req, res) {
  try {
    const { course_id, grade_type, score, weight } = req.body;
    const grade = await Grade.create({ course_id, grade_type, score, weight });
    const createdGrade = await Grade.findByPk(grade.id);
    logger.info(`Grade added. ID: ${createdGrade.id} for course: ${course_id}`);
    return res.status(201).json(createdGrade);
  } catch (error) {
    logger.error(`Failed to add grade: ${error.message}`);
    res.status(500).json({ message: "Failed to add grade", error: error.message });
  }
}

async function getGradesByCourse(req, res) {
  try {
    const { courseId } = req.params;
    const grades = await Grade.findAll({ where: { course_id: courseId } });
    logger.info(`Grades fetched for course ID: ${courseId}`);
    res.status(200).json(grades);
  } catch (error) {
    logger.error(`Failed to fetch grades: ${error.message}`);
    res.status(500).json({ message: "Failed to fetch grades", error: error.message });
  }
}

async function deleteGrade(req, res) {
  try {
    const { gradeId } = req.params;
    const grade = await Grade.findByPk(gradeId);
    if (!grade) {
      logger.error(`Delete Grade: Grade not found. ID: ${gradeId}`);
      return res.status(404).json({ message: "Grade not found" });
    }
    await grade.destroy();
    logger.info(`Grade deleted. ID: ${gradeId}`);
    res.status(200).json({ message: "Grade deleted successfully" });
  } catch (error) {
    logger.error(`Failed to delete grade: ${error.message}`);
    res.status(500).json({ message: "Failed to delete grade", error: error.message });
  }
}

async function updateGrade(req, res) {
  try {
    const { gradeId } = req.params;
    const { grade_type, score, weight } = req.body;
    const grade = await Grade.findByPk(gradeId);
    if (!grade) {
      logger.error(`Update Grade: Grade not found. ID: ${gradeId}`);
      return res.status(404).json({ message: "Grade not found" });
    }
    await grade.update({ grade_type, score, weight });
    const updatedGrade = await Grade.findByPk(gradeId);
    logger.info(`Grade updated. ID: ${gradeId}`);
    res.status(200).json(updatedGrade);
  } catch (error) {
    logger.error(`Failed to update grade: ${error.message}`);
    res.status(500).json({ message: "Failed to update grade", error: error.message });
  }
}

module.exports = { addGrade, getGradesByCourse, deleteGrade, updateGrade };