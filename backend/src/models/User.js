const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const User = sequelize.define("User", {
    id: { 
        type: DataTypes.INTEGER, 
        primaryKey: true, 
        autoIncrement: true 
    },
    email: { 
        type: DataTypes.STRING, 
        allowNull: false, 
        unique: true 
    },
    passwordHash: { 
        type: DataTypes.STRING, 
        allowNull: false 
    },
    university: { 
        type: DataTypes.STRING,
        allowNull: true 
    },
    department: { 
        type: DataTypes.STRING,
        allowNull: true 
    },
    verified: {  
        type: DataTypes.BOOLEAN,
        defaultValue: false
    },
    resetToken: { // Şifre sıfırlama token'ı
        type: DataTypes.STRING,
        allowNull: true
    },
    resetTokenExpires: { // Reset token süresi
        type: DataTypes.DATE,
        allowNull: true
    },
    // Yeni eklenen refresh token alanları
    refreshToken: {
        type: DataTypes.STRING,
        allowNull: true
    },
    refreshTokenExpires: {
        type: DataTypes.DATE,
        allowNull: true
    }
}, {
    tableName: "Users",
    timestamps: true
});

module.exports = User;