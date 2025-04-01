const { Term, Course } = require("../models");
const User = require("../models/User");

const logger = {
  info: (msg) => console.info(`[${new Date().toISOString()}] INFO: ${msg}`),
  error: (msg) => console.error(`[${new Date().toISOString()}] ERROR: ${msg}`)
};

async function createTerm(req, res) {
  try {
    const user_id = parseInt(req.body.user_id);
    const class_level = req.body.class_level.toString();
    const term_number = parseInt(req.body.term_number);

    if (isNaN(user_id) || isNaN(term_number) || !class_level) {
      logger.error("Create Term: Geçersiz parametre formatı.");
      return res.status(400).json({ message: "Geçersiz parametre formatı" });
    }

    const term = await Term.create({
      user_id: user_id,
      class_level: class_level,
      term_number: term_number
    });
    logger.info(`Term created. ID: ${term.id} for user ID: ${user_id}`);
    res.status(201).json(term);
  } catch (error) {
    logger.error(`Dönem eklenirken hata oluştu: ${error.message}`);
    res.status(500).json({ message: "Dönem eklenirken hata oluştu", error: error.message });
  }
}

async function getTermsByUser(req, res) {
  try {
    if (!req.user || !req.user.userId) {
      logger.error("Get Terms: Unauthorized access attempt.");
      return res.status(401).json({ message: "Unauthorized" });
    }

    const userId = req.user.userId;
    const terms = await Term.findAll({
      where: { user_id: userId },
      include: [{
        model: User,
        attributes: ["email", "university", "department"]
      }],
      order: [["class_level", "ASC"], ["term_number", "ASC"]]
    });
    logger.info(`Terms fetched for user ID: ${userId}`);
    res.status(200).json(terms);
  } catch (error) {
    logger.error(`Error getting terms: ${error.message}`);
    res.status(500).json({ message: "Error getting terms", error: error.message });
  }
}

async function deleteTerm(req, res) {
  try {
    if (!req.user || !req.user.userId) {
      logger.error("Delete Term: Kullanıcı kimliği doğrulanamadı.");
      return res.status(401).json({ message: "Kullanıcı kimliği doğrulanamadı" });
    }

    const userId = req.user.userId;
    const termId = req.params.id;
    const term = await Term.findOne({ where: { id: termId, user_id: userId } });
    if (!term) {
      logger.error(`Delete Term: Dönem bulunamadı. ID: ${termId}`);
      return res.status(404).json({ message: "Dönem bulunamadı" });
    }
    await term.destroy();
    logger.info(`Term deleted. ID: ${termId}`);
    res.status(200).json({ message: "Dönem başarıyla silindi" });
  } catch (error) {
    logger.error(`Dönem silinirken hata oluştu: ${error.message}`);
    res.status(500).json({ message: "Dönem silinirken hata oluştu", error: error.message });
  }
}

async function updateTermGPA(req, res) {
  try {
    const { termId } = req.params;
    const updatedCourses = await Course.findAll({ where: { term_id: termId } });

    if (!updatedCourses.length) {
      logger.info(`Update Term GPA: Ders bulunamadı. Term ID: ${termId}`);
      return res.status(200).json({
        termId,
        gpa: 0.0,
        totalCredits: 0,
        message: "Bu dönem için ders bulunamadı."
      });
    }

    let totalCredits = 0;
    let totalWeightedGPA = 0;
    updatedCourses.forEach(course => {
      if (course.gpa !== null && course.credits > 0) {
        totalWeightedGPA += parseFloat(course.gpa) * parseFloat(course.credits);
        totalCredits += parseFloat(course.credits);
      }
    });

    if (totalCredits === 0) {
      logger.info(`Update Term GPA: Geçerli kredi bulunamadı. Term ID: ${termId}`);
      return res.status(200).json({
        termId,
        gpa: 0.0,
        totalCredits: 0,
        message: "Bu dönem için geçerli kredi bulunamadı, GPA 0 olarak ayarlandı."
      });
    }

    const termGPA = (totalWeightedGPA / totalCredits).toFixed(2);
    await Term.update({ gpa: termGPA }, { where: { id: termId } });
    logger.info(`Term GPA updated. Term ID: ${termId}, GPA: ${termGPA}`);

    res.status(200).json({
      termId,
      gpa: parseFloat(termGPA),
      totalCredits
    });
  } catch (error) {
    logger.error(`Dönem GPA hesaplanırken hata oluştu: ${error.message}`);
    res.status(500).json({
      message: "Dönem GPA hesaplanırken hata oluştu.",
      error: error.message
    });
  }
}

module.exports = {
  createTerm,
  getTermsByUser,
  deleteTerm,
  updateTermGPA
};