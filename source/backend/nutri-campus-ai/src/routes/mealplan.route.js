const express = require("express");
const router = express.Router();
const mealplanController = require("../controllers/mealplan.controller");

router.post("/generate", mealplanController.generateMealPlan);

router.post("/rate-dish", mealplanController.rateDish);

router.get("/top-dishes", mealplanController.getTopDishes);
router.get("/disliked-dishes", mealplanController.getDislikedDishes);
router.get("/top-dishes-week", mealplanController.getTopDishes);
router.get("/disliked-dishes-week", mealplanController.getDislikedDishes);



module.exports = router;
