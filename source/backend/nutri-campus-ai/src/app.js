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
    const bottomDishes = await mealplanService.getDislikedDishes();
    const bottomDishesWeekly = await mealplanService.getDislikedDishesWeek();
    const topDishesWeekly = await mealplanService.getTopDishesWeek();
    res.render("index", {
      topDishes,
      bottomDishes,
      topDishesWeekly,
      bottomDishesWeekly,
    });
  } catch (error) {
    console.error(error);
    res.status(500).send("Server Error");
  }
});

app.use("/api/mealplan", mealplanRoutes);

module.exports = app;
