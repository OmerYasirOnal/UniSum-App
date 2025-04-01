require("dotenv").config(); // .env dosyasındaki değişkenlerin yüklenmesi

// Güvenlik ve kripto modülleri
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
bcrypt.setRandomFallback(() => crypto.randomBytes(16));

// Temel modüller
const express = require("express");
const cors = require("cors");
const path = require("path");

// Kendi modüllerimiz
const { connectDB } = require("./config/db");
const logger = require('./utils/logger');
const { generalLimiter } = require('./middlewares/rateLimiter');
const securityMiddleware = require('./middlewares/securityMiddleware');
const { notFoundHandler, errorHandler } = require('./middlewares/errorHandler');

// Express uygulaması
const app = express();

// Güvenlik ayarları
app.set('trust proxy', true);
app.use(securityMiddleware.helmet);
app.use(securityMiddleware.contentSecurityPolicy);

// CORS konfigürasyonu
app.use(cors({
    origin: '*', // Üretim ortamında daha kısıtlayıcı olmalı
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true
}));

// Body parser ve XSS koruması
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(securityMiddleware.xssProtection);
app.use(securityMiddleware.corsErrorHandler);

// Genel hız sınırlama
app.use(generalLimiter);

// Statik dosyaları servis et
app.use(express.static(path.join(__dirname, "public")));

// Routes
const routes = {
    auth: require("./routes/authRoutes"),
    term: require("./routes/termRoutes"),
    course: require("./routes/courseRoutes"),
    grade: require("./routes/gradeRoutes"),
    gpa: require("./routes/gpaRoutes"),
    gradeScale: require("./routes/gradeScaleRoutes")
};

// Route registration
app.use("/auth", routes.auth);
app.use("/", routes.course);
app.use("/terms", routes.term);
app.use("/grades", routes.grade);
app.use("/gpa", routes.gpa);
app.use("/grade-scales", routes.gradeScale);

// Reset Password GET route (HTML form)
app.get("/reset-password", (req, res) => {
    res.sendFile(path.join(__dirname, "public", "resetPassword.html"));
});

// 404 ve error handling middleware'ler
app.use(notFoundHandler);
app.use(errorHandler);

// Server başlatma
const PORT = process.env.PORT || 3000;
const startServer = async () => {
    try {
        // Veritabanı bağlantısı
        await connectDB();
        
        // Sunucuyu başlat
        app.listen(PORT, () => {
            logger.info(`Server running on port ${PORT}`);
        });
    } catch (error) {
        logger.error(`Server failed to start: ${error.message}`);
        process.exit(1);
    }
};

// Sunucuyu çalıştır
startServer();

// Beklenmedik hataları yakala
process.on('uncaughtException', (error) => {
    logger.error(`Uncaught Exception: ${error.message}`);
    logger.error(error.stack);
    process.exit(1);
});

process.on('unhandledRejection', (error) => {
    logger.error(`Unhandled Rejection: ${error.message}`);
    logger.error(error.stack);
    process.exit(1);
});

module.exports = app;