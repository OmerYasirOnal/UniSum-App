const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");
const Term = require("./Term");

const Course = sequelize.define("Course", {
    id: { 
        type: DataTypes.INTEGER, 
        primaryKey: true, 
        autoIncrement: true 
    },
    term_id: { 
        type: DataTypes.INTEGER, 
        allowNull: false 
    },
    user_id: { 
        type: DataTypes.INTEGER, 
        allowNull: false 
    },
    name: { 
        type: DataTypes.STRING, 
        allowNull: false, 
        field: "course_name" 
    },
    credits: { 
        type: DataTypes.DOUBLE, 
        allowNull: false 
    },
    average: { 
        type: DataTypes.DOUBLE, 
        defaultValue: 0 
    },
    gpa: {  // 📌 Yeni eklenen alan
        type: DataTypes.DOUBLE,
        defaultValue: 0
    }
}, {
    tableName: "Courses",
    timestamps: true
});

Term.hasMany(Course, { foreignKey: "term_id" });
Course.belongsTo(Term, { foreignKey: "term_id" });

module.exports = Course;
