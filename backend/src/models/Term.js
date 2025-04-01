const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");
const User = require("./User");

const Term = sequelize.define("Term", {
    id: { 
        type: DataTypes.INTEGER, 
        primaryKey: true, 
        autoIncrement: true 
    },
    user_id: { 
        type: DataTypes.INTEGER, 
        allowNull: false 
    },
    class_level: { 
        type: DataTypes.STRING, 
        allowNull: false,
        validate: {
            isIn: [["pre", "1", "2", "3", "4", "5", "6"]]
        }
    },
    term_number: { 
        type: DataTypes.INTEGER, 
        allowNull: false 
    },
    gpa: {  // 📌 Yeni eklenen alan
        type: DataTypes.DOUBLE,
        defaultValue: 0
    }
}, {
    tableName: "Terms",
    timestamps: true
});

User.hasMany(Term, { foreignKey: "user_id" });
Term.belongsTo(User, { foreignKey: "user_id" });

module.exports = Term;
