const express = require("express");
const router = express.Router();

// Middleware'ler
const authMiddleware = require("../middlewares/authMiddleware");
const { validateSignup, validateLogin, validatePasswordReset } = require("../middlewares/validator");
const { authLimiter } = require("../middlewares/rateLimiter");

// Controller fonksiyonları
const { 
    signup, 
    login, 
    verifyEmail, 
    requestPasswordReset, 
    resetPassword, 
    deleteAccount,
    refreshToken,
    checkVerification,
    resendVerification
} = require("../controllers/authController");

/**
 * @route   POST /auth/signup
 * @desc    Yeni kullanıcı kaydı
 * @access  Public
 */
router.post("/signup", authLimiter, validateSignup, signup);

/**
 * @route   POST /auth/login
 * @desc    Kullanıcı girişi
 * @access  Public
 */
router.post("/login", authLimiter, validateLogin, login);

/**
 * @route   GET /auth/verify-email
 * @desc    E-posta doğrulama
 * @access  Public
 */
router.get("/verify-email", verifyEmail);

/**
 * @route   POST /auth/password-reset
 * @desc    Şifre sıfırlama talebi
 * @access  Public
 */
router.post("/password-reset", authLimiter, requestPasswordReset);

/**
 * @route   POST /auth/reset-password
 * @desc    Yeni şifre belirleme
 * @access  Public
 */
router.post("/reset-password", authLimiter, validatePasswordReset, resetPassword);

/**
 * @route   POST /auth/refresh-token
 * @desc    Erişim token'ını yenileme
 * @access  Public
 */
router.post("/refresh-token", refreshToken);

/**
 * @route   POST /auth/check-verification
 * @desc    E-posta doğrulama durumunu kontrol etme
 * @access  Public
 */
router.post("/check-verification", authLimiter, checkVerification);

/**
 * @route   POST /auth/resend-verification
 * @desc    Doğrulama e-postasını yeniden gönderme
 * @access  Public
 */
router.post("/resend-verification", authLimiter, resendVerification);

/**
 * @route   DELETE /auth/delete-account
 * @desc    Kullanıcı hesabını silme
 * @access  Private
 */
router.delete("/delete-account", authMiddleware, deleteAccount);

module.exports = router;