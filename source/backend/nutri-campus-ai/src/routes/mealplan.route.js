const express = require("express");
const router = express.Router();
const mealplanController = require("../controllers/mealplan.controller");

router.post("/generate", mealplanController.generateMealPlan);

router.post("/rate-dish", mealplanController.rateDish);

router.get("/top-dishes", mealplanController.getTopDishes);


module.exports = router;
