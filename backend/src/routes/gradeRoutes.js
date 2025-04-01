const express = require("express");
const router = express.Router();
const authMiddleware = require("../middlewares/authMiddleware");
const { 
    addGrade, 
    getGradesByCourse, 
    deleteGrade, 
    updateGrade 
} = require("../controllers/gradeController");

router.post("/", authMiddleware, addGrade);
router.get("/courses/:courseId", authMiddleware, getGradesByCourse);
router.delete("/:gradeId", authMiddleware, deleteGrade);
router.put("/:gradeId", authMiddleware, updateGrade);

module.exports = router;