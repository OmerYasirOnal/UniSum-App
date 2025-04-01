const express = require("express");
const router = express.Router();
const authMiddleware = require("../middlewares/authMiddleware");
const { 
    getGradeScales, 
    saveCustomScales, 
    deleteCustomScales 
} = require("../controllers/gradeScaleController");

router.get("/courses/:courseId", authMiddleware, getGradeScales);
router.post("/courses/:courseId", authMiddleware, saveCustomScales);
router.delete("/courses/:courseId", authMiddleware, deleteCustomScales);

module.exports = router;