const express = require("express");
// const mealplanRoutes = require("./routes/mealplan.route");


const app = express();

app.use(express.json());
// app.use("/api/mealplan", mealplanRoutes);
module.exports = app;