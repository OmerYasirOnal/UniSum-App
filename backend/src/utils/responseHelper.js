/**
 * API yanıtları için yardımcı fonksiyonlar
 */
const responseHelper = {
  /**
   * Başarılı işlem yanıtı
   * @param {Object} res - Express response nesnesi
   * @param {Object} data - Yanıt verileri
   * @param {string} message - Başarı mesajı
   * @param {number} statusCode - HTTP durum kodu
   */
  success: (res, data = {}, message = 'İşlem başarılı', statusCode = 200) => {
    return res.status(statusCode).json({
      success: true,
      message,
      ...data,
      timestamp: new Date().toISOString()
    });
  },
  
  /**
   * Hata yanıtı
   * @param {Object} res - Express response nesnesi
   * @param {string} message - Hata mesajı
   * @param {number} statusCode - HTTP durum kodu
   * @param {Error} error - Hata nesnesi (opsiyonel)
   */
  error: (res, message = 'Bir hata oluştu', statusCode = 500, error = null) => {
    const response = {
      success: false,
      message,
      timestamp: new Date().toISOString()
    };
    
    // Geliştirme ortamında hata detaylarını ekle
    if (process.env.NODE_ENV !== 'production' && error) {
      response.error = error.message;
      response.stack = error.stack;
    }
    
    return res.status(statusCode).json(response);
  },
  
  /**
   * Bulunamadı yanıtı
   * @param {Object} res - Express response nesnesi
   * @param {string} message - Bulunamadı mesajı
   */
  notFound: (res, message = 'Kayıt bulunamadı') => {
    return res.status(404).json({
      success: false,
      message,
      timestamp: new Date().toISOString()
    });
  },
  
  /**
   * Geçersiz istek yanıtı
   * @param {Object} res - Express response nesnesi
   * @param {string} message - Geçersiz istek mesajı
   */
  badRequest: (res, message = 'Geçersiz istek') => {
    return res.status(400).json({
      success: false,
      message,
      timestamp: new Date().toISOString()
    });
  },
  
  /**
   * Yetkisiz erişim yanıtı
   * @param {Object} res - Express response nesnesi
   * @param {string} message - Yetkisiz erişim mesajı
   */
  unauthorized: (res, message = 'Yetkisiz erişim') => {
    return res.status(401).json({
      success: false,
      message,
      timestamp: new Date().toISOString()
    });
  },
  
  /**
   * Yasak erişim yanıtı
   * @param {Object} res - Express response nesnesi
   * @param {string} message - Yasak erişim mesajı
   */
  forbidden: (res, message = 'Bu işlem için yetkiniz yok') => {
    return res.status(403).json({
      success: false,
      message,
      timestamp: new Date().toISOString()
    });
  }
};

module.exports = responseHelper; 