const express = require("express");
const router = express.Router();
const authMiddleware = require("../middlewares/authMiddleware");
const { 
    createCourse, 
    getCoursesByTerm, 
    deleteCourse, 
    updateCourseAverage,
    updateCourseGPA,
    updateAllCoursesGPAByTerm
} = require("../controllers/courseController");

router.get("/terms/:termId/courses", authMiddleware, getCoursesByTerm);
router.post("/terms/:termId/courses", authMiddleware, createCourse);
router.delete("/courses/:courseId", authMiddleware, deleteCourse);
router.put("/courses/:courseId/average", authMiddleware, updateCourseAverage);
router.put("/courses/:courseId/updateGPA", updateCourseGPA);
router.put("/updateAllCoursesGPA/:termId", updateAllCoursesGPAByTerm);

module.exports = router;