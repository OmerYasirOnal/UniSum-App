const express = require("express");
const router = express.Router();
const authMiddleware = require("../middlewares/authMiddleware");
const { calculateGPA, getTermGPA } = require("../controllers/gpaController");

router.get("/", authMiddleware, calculateGPA);
router.get("/terms/:termId", authMiddleware, getTermGPA);

module.exports = router;