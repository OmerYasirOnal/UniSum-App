const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");
const Course = require("./Course");

const GradeScale = sequelize.define("GradeScale", {
    id: { 
        type: DataTypes.INTEGER, 
        primaryKey: true, 
        autoIncrement: true 
    },
    course_id: { 
        type: DataTypes.INTEGER, 
        allowNull: false, 
        references: { model: "Courses", key: "id" } 
    },
    letter: { 
        type: DataTypes.STRING, 
        allowNull: false 
    },
    min_score: { 
        type: DataTypes.INTEGER, 
        allowNull: false 
    },
    gpa: { 
        type: DataTypes.DOUBLE, 
        allowNull: false 
    },
    is_custom: { 
        type: DataTypes.BOOLEAN, 
        defaultValue: false 
    }
}, {
    tableName: "GradeScales",
    timestamps: true
});

Course.hasMany(GradeScale, { foreignKey: "course_id", onDelete: "CASCADE" });
GradeScale.belongsTo(Course, { foreignKey: "course_id" });

module.exports = GradeScale;