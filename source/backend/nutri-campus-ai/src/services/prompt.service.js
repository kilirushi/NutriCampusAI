const fs = require("fs");
const path = require("path");

const promptPath = path.join(__dirname, "../prompts/mealplan.prompt.txt");

function buildMealPlanPrompt({ bmi, calories, menu }) {
  let prompt = fs.readFileSync(promptPath, "utf-8");

  prompt = prompt
    .replace("{{BMI}}", bmi.toFixed(1))
    .replace("{{CALORIES}}", calories)
    .replace("{{MENU}}", JSON.stringify(menu, null, 2));

  return prompt;
}

module.exports = { buildMealPlanPrompt };
