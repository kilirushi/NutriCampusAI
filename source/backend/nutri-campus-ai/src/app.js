const express = require("express");
const path = require("path");
const mealplanRoutes = require("./routes/mealplan.route");

const app = express();

app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

app.use(express.json());

app.get("/", (req, res) => {
    res.render("index");
});

app.use("/api/mealplan", mealplanRoutes);
module.exports = app;