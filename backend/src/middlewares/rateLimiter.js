const rateLimit = require('express-rate-limit');
const logger = require('../utils/logger');

/**
 * Genel API istekleri için rate limiter
 */
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 100, // Her IP başına 15 dakikada maksimum 100 istek
  standardHeaders: true, // Rate limiter bilgilerini standart RateLimit başlıklarında döndür
  legacyHeaders: false, // X-RateLimit başlıklarını devre dışı bırak
  handler: (req, res) => {
    logger.warn(`Rate limit aşıldı: ${req.ip}`);
    return res.status(429).json({
      success: false,
      message: 'Çok fazla istek gönderildi, lütfen daha sonra tekrar deneyin',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * Kimlik doğrulama istekleri için daha sıkı rate limiter
 */
const authLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 saat
  max: 10, // Her IP başına 1 saatte maksimum 10 istek
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn(`Auth rate limit aşıldı: ${req.ip}`);
    return res.status(429).json({
      success: false,
      message: 'Çok fazla kimlik doğrulama isteği gönderildi, lütfen daha sonra tekrar deneyin',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = {
  generalLimiter,
  authLimiter
}; 