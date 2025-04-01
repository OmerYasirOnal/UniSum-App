const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");
const Course = require("./Course");

const Grade = sequelize.define("Grade", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    course_id: { type: DataTypes.INTEGER, allowNull: false },
    grade_type: { type: DataTypes.STRING, allowNull: false }, // Örn: Vize, Final
    score: { type: DataTypes.DOUBLE, allowNull: false },
    weight: { type: DataTypes.DOUBLE, allowNull: false }
}, {
    tableName: "Grades",
    timestamps: true
});

Course.hasMany(Grade, { foreignKey: "course_id" });
Grade.belongsTo(Course, { foreignKey: "course_id" });

module.exports = Grade;