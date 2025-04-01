const logger = require('../utils/logger');

/**
 * 404 hata middleware'i
 * İstek yapılan rota bulunamadığında çalışır
 */
const notFoundHandler = (req, res) => {
  logger.warn(`404 - Route bulunamadı: ${req.method} ${req.originalUrl} - IP: ${req.ip}`);
  
  return res.status(404).json({
    success: false,
    message: "Route not found",
    path: req.originalUrl,
    method: req.method,
    timestamp: new Date().toISOString()
  });
};

/**
 * Genel hata işleme middleware'i
 * Uygulama içinde fırlatılan hataları yakalar ve işler
 */
const errorHandler = (err, req, res, next) => {
  // Hata tipi ve mesajını logla
  logger.error(`Hata: ${err.message}`);
  if (err.stack) {
    logger.error(`Stack: ${err.stack}`);
  }
  
  // HTTP durum kodunu belirle (varsayılan: 500)
  const statusCode = err.statusCode || 500;
  
  // Yanıtı hazırla
  const errorResponse = {
    success: false,
    message: statusCode === 500 ? "Internal Server Error" : err.message,
    timestamp: new Date().toISOString()
  };
  
  // Geliştirme ortamında hata detaylarını ekle
  if (process.env.NODE_ENV !== 'production') {
    errorResponse.stack = err.stack;
    
    if (err.errors) {
      errorResponse.errors = err.errors;
    }
  }
  
  return res.status(statusCode).json(errorResponse);
};

// Özel hata sınıfları
class ApiError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

class NotFoundError extends ApiError {
  constructor(message = 'Resource not found') {
    super(message, 404);
  }
}

class ValidationError extends ApiError {
  constructor(message = 'Validation failed', errors = null) {
    super(message, 400);
    this.errors = errors;
  }
}

class AuthorizationError extends ApiError {
  constructor(message = 'Unauthorized access') {
    super(message, 401);
  }
}

class ForbiddenError extends ApiError {
  constructor(message = 'Forbidden access') {
    super(message, 403);
  }
}

module.exports = {
  notFoundHandler,
  errorHandler,
  ApiError,
  NotFoundError,
  ValidationError,
  AuthorizationError,
  ForbiddenError
}; 