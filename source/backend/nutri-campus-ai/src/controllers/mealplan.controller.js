const mealplanService = require("../services/mealplan.service");
const { success, error } = require("../utils/response.util");

const generateMealPlan = async (req, res) => {
  try {
    const { student_id, height_cm, weight_kg } = req.body;
    console.log(student_id,height_cm,weight_kg);
    if (!student_id || !height_cm || !weight_kg) {
      return res.status(400).json({ message: "Missing parameters" });
    }
    const mealPlan = await mealplanService.createMealPlan(student_id, height_cm, weight_kg);
    return success(res, mealPlan, "Generate meal plan successfully");
  } catch (err) {
    console.error(err);
    return error(res, 500, "Failed to generate meal plan");
  }
};

const rateDish = async (req, res) => {
  try {
    const { student_id, week_start, day, ratings } = req.body;

    if (!student_id || !week_start || !day || !ratings) {
      return res.status(400).json({
        code: 400,
        message: "Missing required data: studentId, weekStart, day, ratings",
        data: null
      });
    }

    await mealplanService.saveDishRatings(student_id, week_start, day, ratings);

    return res.json({
      code: 200,
      message: "Dish ratings saved successfully",
      data: ratings
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({
      code: 500,
      message: "Failed to save dish ratings",
      data: null
    });
  }
};

const getTopDishes = async (req, res) => {
  try {
    const topDishes = await mealplanService.getTopDishes();

    return res.json({
      code: 200,
      message: "Dish ratings saved successfully",
      data: topDishes
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({
      code: 500,
      message: "Failed to save dish ratings",
      data: null
    });
  }
};

module.exports = { generateMealPlan,rateDish,getTopDishes };
