/**
 * Giriş verilerini doğrulamak için yardımcı fonksiyonlar
 */

const responseHelper = require('../utils/responseHelper');

/**
 * E-posta formatını doğrulayan fonksiyon
 * @param {string} email - Doğrulanacak e-posta
 * @returns {boolean} E-posta formatı geçerli mi?
 */
const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

/**
 * Şifre gücünü doğrulayan fonksiyon
 * En az 8 karakter, en az bir büyük harf, bir küçük harf ve bir sayı içermeli
 * @param {string} password - Doğrulanacak şifre
 * @returns {boolean} Şifre güçlü mü?
 */
const isStrongPassword = (password) => {
  if (!password || password.length < 8) return false;
  
  // Basit bir şifre kontrolü - gerçek uygulamada daha kapsamlı olabilir
  const hasUpperCase = /[A-Z]/.test(password);
  const hasLowerCase = /[a-z]/.test(password);
  const hasNumbers = /\d/.test(password);
  
  return hasUpperCase && hasLowerCase && hasNumbers;
};

/**
 * Kayıt isteğini doğrulayan middleware
 */
const validateSignup = (req, res, next) => {
  const { email, password, university, department } = req.body;
  
  if (!email || !password) {
    return responseHelper.badRequest(res, 'error_email_password_required');
  }
  
  if (!isValidEmail(email)) {
    return responseHelper.badRequest(res, 'error_invalid_email_format');
  }
  
  if (!isStrongPassword(password)) {
    return responseHelper.badRequest(res, 'error_weak_password');
  }
  
  next();
};

/**
 * Giriş isteğini doğrulayan middleware
 */
const validateLogin = (req, res, next) => {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return responseHelper.badRequest(res, 'error_email_password_required');
  }
  
  if (!isValidEmail(email)) {
    return responseHelper.badRequest(res, 'error_invalid_email_format');
  }
  
  next();
};

/**
 * Şifre sıfırlama isteğini doğrulayan middleware
 */
const validatePasswordReset = (req, res, next) => {
  const { token, password } = req.body;
  
  if (!token || !password) {
    return responseHelper.badRequest(res, 'error_token_password_required');
  }
  
  if (!isStrongPassword(password)) {
    return responseHelper.badRequest(res, 'error_weak_password');
  }
  
  next();
};

module.exports = {
  validateSignup,
  validateLogin,
  validatePasswordReset,
  isValidEmail,
  isStrongPassword
}; 