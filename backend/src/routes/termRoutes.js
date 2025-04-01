const express = require("express");
const router = express.Router();
const authMiddleware = require("../middlewares/authMiddleware");
const { 
    createTerm, 
    getTermsByUser, 
    deleteTerm,
    updateTermGPA
} = require("../controllers/termController");

router.get("/my-terms", authMiddleware, getTermsByUser);
router.post("/", authMiddleware, createTerm);
router.delete('/:id', authMiddleware, deleteTerm);
router.put("/:termId/updateGPA", updateTermGPA);

module.exports = router;