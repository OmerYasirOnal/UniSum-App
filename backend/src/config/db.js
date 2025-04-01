require("dotenv").config();
const { Sequelize } = require("sequelize");

const sequelize = new Sequelize(
  process.env.DB_NAME,       // Örneğin: UniDB
  process.env.DB_USER,       // Örneğin: Seir
  process.env.DB_PASS,       // Örneğin: 123987456Asd*
  {
    host: process.env.DB_HOST,  // Örneğin: 141.147.25.123
    port: process.env.DB_PORT,  // Örneğin: 3306
    dialect: "mysql",
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    dialectOptions: {
      connectTimeout: 8640000
    },
    logging: false // Sequelize logları kapalı
  }
);

const connectDB = async () => {
  try {
    await sequelize.authenticate();
    console.info(`[${new Date().toISOString()}] INFO: Database connected successfully.`);
  } catch (error) {
    console.error(`[${new Date().toISOString()}] ERROR: Database connection failed. ${error.message}`);
    process.exit(1);
  }
};

module.exports = { sequelize, connectDB };