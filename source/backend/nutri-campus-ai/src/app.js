const express = require("express");
const path = require("path");
const mealplanRoutes = require("./routes/mealplan.route");
const mealplanService = require("./services/mealplan.service");

const app = express();

app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "view"));

app.use(express.static(path.join(__dirname, "view")));

app.get("/", async (req, res) => {
    try {
        const topDishes = await mealplanService.getTopDishes();
        console.log(topDishes);
        res.render("index", { topDishes });

    } catch (error) {
        console.error(error);
        res.status(500).send("Server Error");
    }
});

app.use("/api/mealplan", mealplanRoutes);

module.exports = app;