const express = require("express");
const mealplanRoutes = require("./routes/mealplan.route");


const app = express();

app.use(express.json());

app.set("view engine", "ejs");
app.set("views", __dirname + "/views");

app.get("/", (req, res) => {
    res.render("index", { name: "Erica" });
});

app.use("/api/mealplan", mealplanRoutes);
module.exports = app;