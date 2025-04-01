const nodemailer = require("nodemailer");
require("dotenv").config();

const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    }
});

/**
 * Kullanıcıya doğrulama e-postası gönder
 */
async function sendVerificationEmail(email, token) {
    try {
      const frontendUrl = process.env.FRONTEND_URL || "https://localhost";
      const verificationLink = `${frontendUrl}/auth/verify-email?token=${token}`;
  
      const mailOptions = {
        from: process.env.EMAIL_USER,
        to: email,
        subject: "E-posta Doğrulama",
        html: `<p>Hesabınızı doğrulamak için aşağıdaki bağlantıya tıklayın:</p>
               <a href="${verificationLink}">${verificationLink}</a>`
      };
  
      await transporter.sendMail(mailOptions);
      console.log("✅ Email doğrulama bağlantısı gönderildi:", verificationLink);
      
      // Opsiyonel: Gönderim başarılı ise verificationLink bilgisini döndür
      return verificationLink;
    } catch (error) {
      console.error("⚠️ Email gönderme hatası:", error.message);
      throw error;
    }
  }
/**
 * Kullanıcıya şifre sıfırlama e-postası gönder
 */
async function sendPasswordResetEmail(email, token) {
    try {
      // FRONTEND_URL .env dosyanızda tanımlı, örneğin: http://192.168.201.16
      const frontendUrl = process.env.FRONTEND_URL || "https://localhost";
      const resetUrl = `${frontendUrl}/reset-password?token=${token}`;
  
      const mailOptions = {
        from: process.env.EMAIL_USER,
        to: email,
        subject: "Şifre Sıfırlama Talebi",
        html: `<h2>Şifre Sıfırlama Talebiniz</h2>
               <p>Yeni şifre belirlemek için aşağıdaki bağlantıya tıklayın:</p>
               <a href="${resetUrl}">Şifreyi Sıfırla</a>`
      };
  
      await transporter.sendMail(mailOptions);
      console.log(`✅ Şifre sıfırlama e-postası gönderildi: ${email}`);
    } catch (error) {
      console.error("❌ E-posta gönderme hatası:", error);
    }
  }

module.exports = { sendVerificationEmail, sendPasswordResetEmail };