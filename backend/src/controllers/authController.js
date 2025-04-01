const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs"); // bcrypt yerine bcryptjs kullan
const { User } = require("../models");
const crypto = require("crypto");
const { sendVerificationEmail, sendPasswordResetEmail } = require("../services/emailService");
require("dotenv").config();
const path = require("path");

// Basit bir logger yardımcı fonksiyonu
const logger = {
  info: (msg) => console.info(`[${new Date().toISOString()}] INFO: ${msg}`),
  error: (msg) => console.error(`[${new Date().toISOString()}] ERROR: ${msg}`)
};

// Kullanıcı hesabını silme
async function deleteAccount(req, res) {
    try {
        const userId = req.user.userId; // auth token'dan gelen ID
        const user = await User.findByPk(userId);

        if (!user) {
            logger.error(`Delete Account: Kullanıcı bulunamadı. ID: ${userId}`);
            return res.status(404).json({ 
                success: false,
                message: "error_user_not_found"
            });
        }

        await user.destroy();
        logger.info(`Delete Account: Kullanıcı hesabı silindi. ID: ${userId}`);
        return res.status(200).json({
            success: true,
            message: "account_deleted_successfully"
        });
    } catch (error) {
        logger.error(`Account deletion error: ${error.message}`);
        return res.status(500).json({
            success: false,
            message: "error_account_deletion_failed",
            error: error.message
        });
    }
}

/**
 * Kullanıcı kaydı işlemi
 */
async function signup(req, res) {
    const { email, password, university, department } = req.body;

    if (!email || !password) {
        logger.error("Signup: E-posta veya şifre eksik.");
        return res.status(400).json({ 
            success: false,
            message: "error_email_password_required" 
        });
    }

    try {
        const existingUser = await User.findOne({ where: { email } });
        if (existingUser) {
            logger.error(`Signup: E-posta zaten kayıtlı - ${email}`);
            return res.status(409).json({ 
                success: false,
                message: "error_email_exists" 
            });
        }

        // bcryptjs ile şifre hashleme
        const salt = bcrypt.genSaltSync(10);
        const passwordHash = bcrypt.hashSync(password, salt);

        const newUser = await User.create({ email, passwordHash, university, department });
        logger.info(`Signup: Yeni kullanıcı oluşturuldu. ID: ${newUser.id}, Email: ${email}`);

        const verificationToken = jwt.sign(
            { userId: newUser.id },
            process.env.JWT_SECRET,
            { expiresIn: "24h" }
        );

        const verificationLink = await sendVerificationEmail(email, verificationToken);
        logger.info(`Signup: Doğrulama e-postası gönderildi - ${email}`);

        return res.status(201).json({ 
            success: true,
            message: "verification_email_sent",
            verificationLink: verificationLink
        });
    } catch (error) {
        logger.error(`Signup error: ${error.message}`);
        return res.status(500).json({ 
            success: false,
            message: "error_unknown", 
            error: error.message 
        });
    }
}

/**
 * Kullanıcı girişi işlemi
 */
async function login(req, res) {
    const { email, password } = req.body;

    try {
        const user = await User.findOne({ where: { email } });
        if (!user) {
            logger.error(`Login: Kullanıcı bulunamadı - ${email}`);
            return res.status(401).json({ 
                success: false,
                message: "error_invalid_credentials" 
            });
        }

        if (!user.verified) {
            logger.error(`Login: E-posta doğrulanmamış - User ID: ${user.id}`);
            return res.status(403).json({ 
                success: false,
                message: "error_email_not_verified" 
            });
        }

        // Şifre kontrolü
        const isPasswordValid = bcrypt.compareSync(password, user.passwordHash);
        if (!isPasswordValid) {
            logger.error(`Login: Geçersiz kimlik bilgileri - User ID: ${user.id}`);
            return res.status(401).json({ 
                success: false,
                message: "error_invalid_credentials" 
            });
        }

        // Access token oluşturma (1 saat geçerli)
        const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: "24h" });
        
        // Refresh token oluşturma (örneğin, 7 gün geçerli)
        const refreshToken = crypto.randomBytes(64).toString("hex");
        const refreshTokenExpires = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

        // Refresh token bilgilerini kullanıcıya kaydet
        user.refreshToken = refreshToken;
        user.refreshTokenExpires = refreshTokenExpires;
        await user.save();

        logger.info(`Login: Kullanıcı giriş yaptı - ID: ${user.id}`);
        return res.status(200).json({ token, refreshToken, user });
    } catch (error) {
        logger.error(`Login error: ${error.message}`);
        return res.status(500).json({ 
            success: false,
            message: "error_login", 
            error: error.message 
        });
    }
}

async function verifyEmail(req, res) {
    const { token } = req.query;

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findByPk(decoded.userId);

        if (user && !user.verified) {
            await User.update({ verified: true }, { where: { id: user.id } });
            logger.info(`Verify Email: Kullanıcı doğrulandı - ID: ${user.id}`);
        } else {
            logger.info(`Verify Email: Kullanıcı ya zaten doğrulanmış ya da bulunamadı - ID: ${decoded.userId}`);
        }
    } catch (error) {
        logger.error(`Email verification error: ${error.message}`);
    }
    
    // Her durumda aynı HTML'i göster
    return res.sendFile(path.join(__dirname, "../public", "verifyEmail.html"));
}

/**
 * Şifre sıfırlama talebi
 */
async function requestPasswordReset(req, res) {
    const { email } = req.body;

    try {
        const user = await User.findOne({ where: { email } });
        if (!user) {
            logger.error(`Password Reset Request: Kullanıcı bulunamadı - ${email}`);
            return res.status(404).json({ 
                success: false,
                message: "error_user_not_found" 
            });
        }
        
        if (!user.verified) {
            logger.error(`Password Reset Request: Doğrulanmamış e-posta - User ID: ${user.id}`);
            return res.status(403).json({
                success: false,
                message: "error_email_not_verified"
            });
        }

        const resetToken = crypto.randomBytes(32).toString("hex");
        user.resetToken = resetToken;
        user.resetTokenExpires = new Date(Date.now() + 3600000); // 1 saat geçerlilik
        await user.save();

        await sendPasswordResetEmail(email, resetToken);
        logger.info(`Password Reset Request: Şifre sıfırlama e-postası gönderildi - ${email}`);
        return res.status(200).json({ 
            success: true,
            message: "password_reset_email_sent" 
        });
    } catch (error) {
        logger.error(`Password Reset Request error: ${error.message}`);
        return res.status(500).json({ 
            success: false,
            message: "error_password_reset_failed" 
        });
    }
}

/**
 * Şifre sıfırlama işlemi
 */
async function resetPassword(req, res) {
    const { token, newPassword } = req.body;

    try {
        const user = await User.findOne({ where: { resetToken: token } });

        if (!user || user.resetTokenExpires < new Date()) {
            logger.error("Reset Password: Geçersiz veya süresi dolmuş token.");
            return res.status(400).json({ 
                success: false,
                message: "error_invalid_or_expired_reset_token" 
            });
        }

        const salt = bcrypt.genSaltSync(10);
        user.passwordHash = bcrypt.hashSync(newPassword, salt);
        user.resetToken = null;
        user.resetTokenExpires = null;
        await user.save();

        logger.info(`Reset Password: Şifre güncellendi - User ID: ${user.id}`);
        return res.status(200).json({ 
            success: true,
            message: "password_updated_successfully" 
        });
    } catch (error) {
        logger.error(`Reset Password error: ${error.message}`);
        return res.status(500).json({ 
            success: false,
            message: "error_password_update_failed" 
        });
    }
}

/**
 * Token yenileme
 */
async function refreshToken(req, res) {
    const { refreshToken } = req.body;

    if (!refreshToken) {
        logger.error("Token Yenileme: Refresh token sağlanmadı");
        return res.status(400).json({
            success: false,
            message: "error_refresh_token_required"
        });
    }

    try {
        const user = await User.findOne({ where: { refreshToken } });
        if (!user || !user.refreshTokenExpires || user.refreshTokenExpires < new Date()) {
            logger.error("Token Yenileme: Geçersiz veya süresi dolmuş refresh token");
            return res.status(401).json({
                success: false,
                message: "error_invalid_refresh_token"
            });
        }

        // Yeni access token oluşturma
        const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: "24h" });
        
        // Yeni refresh token oluşturma
        const newRefreshToken = crypto.randomBytes(64).toString("hex");
        const refreshTokenExpires = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

        // Refresh token bilgilerini güncelle
        user.refreshToken = newRefreshToken;
        user.refreshTokenExpires = refreshTokenExpires;
        await user.save();

        logger.info(`Token Yenileme: Token yenilendi. User ID: ${user.id}`);
        return res.status(200).json({ 
            token,
            refreshToken: newRefreshToken,
            user
        });
    } catch (error) {
        logger.error(`Token yenileme hatası: ${error.message}`);
        return res.status(500).json({
            success: false,
            message: "error_token_refresh",
            error: error.message
        });
    }
}

/**
 * E-posta doğrulama durumunu kontrol etme
 */
async function checkVerification(req, res) {
    const { email } = req.body;

    if (!email) {
        logger.error("Doğrulama Kontrolü: E-posta adresi sağlanmadı");
        return res.status(400).json({
            success: false,
            message: "error_email_required"
        });
    }

    try {
        const user = await User.findOne({ where: { email } });
        if (!user) {
            logger.error(`Doğrulama Kontrolü: Kullanıcı bulunamadı - ${email}`);
            return res.status(404).json({
                success: false,
                message: "error_user_not_found",
                data: { verified: false }
            });
        }

        logger.info(`Doğrulama Kontrolü: Durum kontrol edildi - ${email}, Verified: ${user.verified}`);
        return res.status(200).json({
            success: true,
            message: user.verified ? "email_verified" : "email_not_verified",
            data: { verified: user.verified }
        });
    } catch (error) {
        logger.error(`Doğrulama kontrolü hatası: ${error.message}`);
        return res.status(500).json({
            success: false,
            message: "error_verification_check",
            error: error.message
        });
    }
}

/**
 * Doğrulama e-postasını yeniden gönderme
 */
async function resendVerification(req, res) {
    const { email } = req.body;

    if (!email) {
        logger.error("Doğrulama Yeniden Gönderme: E-posta adresi sağlanmadı");
        return res.status(400).json({
            success: false,
            message: "error_email_required"
        });
    }

    try {
        const user = await User.findOne({ where: { email } });
        if (!user) {
            logger.error(`Doğrulama Yeniden Gönderme: Kullanıcı bulunamadı - ${email}`);
            return res.status(404).json({
                success: false,
                message: "error_user_not_found"
            });
        }

        if (user.verified) {
            logger.info(`Doğrulama Yeniden Gönderme: Kullanıcı zaten doğrulanmış - ${email}`);
            return res.status(200).json({
                success: true,
                message: "email_already_verified"
            });
        }

        const verificationToken = jwt.sign(
            { userId: user.id },
            process.env.JWT_SECRET,
            { expiresIn: "24h" }
        );

        const verificationLink = await sendVerificationEmail(email, verificationToken);
        logger.info(`Doğrulama Yeniden Gönderme: E-posta gönderildi - ${email}`);

        return res.status(200).json({
            success: true,
            message: "verification_email_sent",
            verificationLink: verificationLink
        });
    } catch (error) {
        logger.error(`Doğrulama e-postası yeniden gönderme hatası: ${error.message}`);
        return res.status(500).json({
            success: false,
            message: "error_resend_verification",
            error: error.message
        });
    }
}

module.exports = {
    signup,
    login,
    verifyEmail,
    requestPasswordReset,
    resetPassword,
    refreshToken,
    checkVerification,
    resendVerification,
    deleteAccount
};