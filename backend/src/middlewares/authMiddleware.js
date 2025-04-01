const jwt = require('jsonwebtoken');
const responseHelper = require('../utils/responseHelper');
const logger = require('../utils/logger');

/**
 * Kullanıcı kimlik doğrulama middleware'i
 * HTTP isteklerindeki Authorization başlığından JWT token'ı doğrular
 */
const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;

  // 1) Authorization başlığı hiç yoksa
  if (!authHeader) {
    logger.warn(`Auth middleware: Authorization başlığı yok - ${req.ip}`);
    return responseHelper.unauthorized(res, "No Authorization header");
  }

  // 2) Format kontrolü: 'Bearer ' ile başlamalı
  if (!authHeader.startsWith('Bearer ')) {
    logger.warn(`Auth middleware: Geçersiz Authorization formatı - ${req.ip}`);
    return responseHelper.unauthorized(res, "Invalid Authorization format");
  }

  // 3) Token'ı ayıklayıp doğrula
  try {
    const token = authHeader.replace('Bearer ', '').trim();
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    logger.error(`Auth middleware: Token doğrulama hatası - ${error.message}`);
    return responseHelper.unauthorized(res, "Invalid token");
  }
};

module.exports = authMiddleware;