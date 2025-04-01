const helmet = require('helmet');

/**
 * Güvenlik ile ilgili middleware'ler
 */
const securityMiddleware = {
  /**
   * Helmet middleware'i ile HTTP başlık güvenliği sağlanır
   */
  helmet: helmet(),
  
  /**
   * Content-Security-Policy ayarları ile kaynakların güvenliği sağlanır
   */
  contentSecurityPolicy: helmet.contentSecurityPolicy({
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    }
  }),
  
  /**
   * CORS hataları için görev yapan middleware
   */
  corsErrorHandler: (err, req, res, next) => {
    if (err.name === 'SyntaxError') {
      return res.status(400).json({
        success: false,
        message: 'Invalid JSON',
        timestamp: new Date().toISOString()
      });
    }
    next(err);
  },
  
  /**
   * XSS saldırılarını önlemek için bir middleware
   */
  xssProtection: (req, res, next) => {
    // Giriş verilerini sanitize et
    if (req.body) {
      Object.keys(req.body).forEach(key => {
        if (typeof req.body[key] === 'string') {
          // Basit bir XSS koruması
          req.body[key] = req.body[key]
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#x27;')
            .replace(/\//g, '&#x2F;');
        }
      });
    }
    next();
  }
};

module.exports = securityMiddleware; 