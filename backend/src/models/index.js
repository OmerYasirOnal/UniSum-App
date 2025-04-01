const { sequelize } = require("../config/db");
const User = require("./User");
const Term = require("./Term");
const Course = require("./Course");
const Grade = require("./Grade");
const GradeScale = require("./GradeScale");

// Model Relations
User.hasMany(Term, { foreignKey: "user_id" });
Term.belongsTo(User, { foreignKey: "user_id" });

Term.hasMany(Course, { foreignKey: "term_id" });
Course.belongsTo(Term, { foreignKey: "term_id" });

Course.hasMany(Grade, { foreignKey: "course_id" });
Grade.belongsTo(Course, { foreignKey: "course_id" });

Course.hasMany(GradeScale, { foreignKey: "course_id" });
GradeScale.belongsTo(Course, { foreignKey: "course_id" });

module.exports = {
    sequelize,
    User,
    Term,
    Course,
    Grade,
    GradeScale
};