/**
 * Uygulama genelinde kullanılabilecek bir loglama yardımcı sınıfı
 */
const logger = {
  /**
   * Bilgi seviyesinde log mesajı
   * @param {string} msg - Log mesajı
   */
  info: (msg) => console.info(`[${new Date().toISOString()}] INFO: ${msg}`),
  
  /**
   * Hata seviyesinde log mesajı
   * @param {string} msg - Log mesajı
   */
  error: (msg) => console.error(`[${new Date().toISOString()}] ERROR: ${msg}`),
  
  /**
   * Uyarı seviyesinde log mesajı
   * @param {string} msg - Log mesajı
   */
  warn: (msg) => console.warn(`[${new Date().toISOString()}] WARN: ${msg}`),
  
  /**
   * Debug seviyesinde log mesajı
   * @param {string} msg - Log mesajı
   */
  debug: (msg) => console.debug(`[${new Date().toISOString()}] DEBUG: ${msg}`)
};

module.exports = logger; 