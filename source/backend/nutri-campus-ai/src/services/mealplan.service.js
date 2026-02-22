const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

const buildMealPlanPrompt = require("../prompts/mealplan.prompt");
const { mealPlanRef,dishStatistics } = require("../models/mealplan.model");
const { calculateCalories } = require("../utils/calorie.util");
const { getWeekMondayISO } = require("../utils/date.util");

const DAYS = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday"
];

const MEAL_TIMES = {
  Breakfast: { start: "01:00", end: "22:00" },
  Lunch: { start: "01:00", end: "22:00" },
  Dinner: { start: "11:00", end: "22:00" }
};

const MEALS = ["Breakfast","Lunch","Dinner"];

const createMealPlan = (studentId, height_cm, weight_kg) => {
  return new Promise((resolve, reject) => {
    try {
      // 1️⃣ Tính BMI + calories
      const { bmi, dailyCalories } = calculateCalories(height_cm, weight_kg);

      // 2️⃣ Load menu
      const menuPath = path.join(__dirname, "../data/dining_hall_menu.json");
      const menuData = JSON.parse(fs.readFileSync(menuPath, "utf-8"));

      // 3️⃣ Build prompt
      const prompt = buildMealPlanPrompt({
        BMI: bmi,
        CALORIES: dailyCalories,
        MENU: menuData
      });

      // 4️⃣ Spawn Ollama
      const child = spawn("ollama", ["run", "llama3.2"], {
        stdio: ["pipe", "pipe", "pipe"]
      });

      let output = "";
      let errorOutput = "";

      child.stdout.on("data", (data) => output += data.toString());
      child.stderr.on("data", (data) => errorOutput += data.toString());

      child.on("close", async (code) => {
        if (code !== 0) return reject(new Error("Ollama error: " + errorOutput));

        try {
          // 5️⃣ Parse JSON
          const jsonStart = output.indexOf("{");
          const jsonEnd = output.lastIndexOf("}");
          const cleanJson = output.substring(jsonStart, jsonEnd + 1);
          const rawPlan = JSON.parse(cleanJson);

          // 6️⃣ Build structured mealPlan
          const mealPlan = { BMI: bmi };

          for (const day of DAYS) {
            if (!rawPlan[day]) throw new Error(`Missing day plan: ${day}`);

            mealPlan[day] = {};

            for (const mealName of MEALS) {
              if (!rawPlan[day][mealName]) throw new Error(`Missing ${mealName} at ${day}`);

              const dishes = Array.isArray(rawPlan[day][mealName])
                ? rawPlan[day][mealName]
                : rawPlan[day][mealName].dishes || [];

              mealPlan[day][mealName] = {
                dishes:dishes,
                time: MEAL_TIMES[mealName]
              };
            }
          }
          
          // 7️⃣ Lưu Firebase
          const weekStart = getWeekMondayISO();
          await mealPlanRef
            .child(studentId)
            .child(`weekOf_${weekStart}`)
            .update({
              bmi,
              dailyCalories,
              createdAt: Date.now(),
              meals: mealPlan
            });

          // 8️⃣ Resolve mealPlan
          resolve(mealPlan);
        } catch (err) {
          reject(err);
        }
      });

      child.stdin.write(prompt);
      child.stdin.end();
    } catch (err) {
      reject(err);
    }
  });
};

/**
 * Lưu đánh giá từng món trong 1 ngày của sinh viên
 * @param {string} studentId
 * @param {string} weekStart - yyyy-mm-dd
 * @param {string} day - "Monday".."Sunday"
 * @param {object} ratings - { Breakfast: { "Oatmeal": 5 }, Lunch: {...}, Dinner: {...} }
 */
const saveDishRatings = async (studentId, weekStart, day, ratings) => {
  const ratingDayRef = mealPlanRef
    .child(studentId)
    .child(`weekOf_${weekStart}`)
    .child("ratings")
    .child(day);

  const snapshot = await ratingDayRef.once("value");
  const existingRatings = snapshot.val() || {};

  const updates = [];

  for (const meal of Object.keys(ratings)) {
    for (const dish of Object.keys(ratings[meal])) {

      const newScore = ratings[meal][dish];
      const oldScore = existingRatings?.[meal]?.[dish] ?? null;

      updates.push(
        updateDishStatistics({
          meal,
          dish,
          newScore,
          oldScore,
          weekStart
        })
      );
    }
  }

  // chạy song song
  await Promise.all(updates);

  await ratingDayRef.set({
    ...ratings,
    updatedAt: Date.now()
  });

  return { success: true };
};



const updateDishStatistics = async ({
  meal,
  dish,
  newScore,
  oldScore,
  weekStart
}) => {

  const globalRef = dishStatistics.child(`global/${meal}/${dish}`);
  const weeklyRef = dishStatistics.child(`weekly/weekOf_${weekStart}/${meal}/${dish}`);

  const updateLogic = async (ref) => {
    await ref.transaction((data) => {

      if (!data) {
        return {
          totalScore: newScore,
          totalCount: 1,
          average: newScore
        };
      }

      let totalScore = data.totalScore || 0;
      let totalCount = data.totalCount || 0;

      if (oldScore === null) {
        // rating mới
        totalScore += newScore;
        totalCount += 1;
      } else {
        // chỉnh sửa rating
        totalScore = totalScore - oldScore + newScore;
      }

      return {
        totalScore,
        totalCount,
        average: parseFloat((totalScore / totalCount).toFixed(2))
      };
    });
  };

  await Promise.all([
    updateLogic(globalRef),
    updateLogic(weeklyRef)
  ]);
};


const getTopDishes = async () => {
  const snapshot = await dishStatistics.child("global").once("value");
  const stats = snapshot.val();
  if (!stats) return null;

  const result = {};

  for (const meal of Object.keys(stats)) {
    const dishes = Object.entries(stats[meal])
      .filter(([_, data]) => data.average > 3)   // 🔥 điều kiện > 3
      .sort((a, b) => a[1].average - b[1].average); // 🔥 sort tăng dần (tệ nhất lên trước)

    result[meal] = dishes.map(([dish, data]) => ({
      dish,
      average: data.average,
      totalVotes: data.totalCount
    }));
  }

  return result;
};

const getDislikedDishes = async () => {
  const weekStart = getWeekMondayISO();
  // const snapshot = await dishStatistics.child(`weekly/weekOf_${weekStart}`).once("value");
  const snapshot = await dishStatistics.child("global").once("value");
  const stats = snapshot.val();
  if (!stats) return null;

  const result = {};

  for (const meal of Object.keys(stats)) {
    const dishes = Object.entries(stats[meal])
      .filter(([_, data]) => data.average < 3)   // 🔥 điều kiện < 3
      .sort((a, b) => a[1].average - b[1].average); // 🔥 sort tăng dần (tệ nhất lên trước)

    result[meal] = dishes.map(([dish, data]) => ({
      dish,
      average: data.average,
      totalVotes: data.totalCount
    }));
  }

  return result;
};


const getTopDishesWeek = async () => {
  const weekStart = getWeekMondayISO();
  const snapshot = await dishStatistics.child(`weekly/weekOf_${weekStart}`).once("value");  
  const stats = snapshot.val();
  if (!stats) return null;

  const result = {};

  for (const meal of Object.keys(stats)) {
    const dishes = Object.entries(stats[meal])
      .filter(([_, data]) => data.average > 3)   // 🔥 điều kiện > 3
      .sort((a, b) => a[1].average - b[1].average); // 🔥 sort tăng dần (tệ nhất lên trước)

    result[meal] = dishes.map(([dish, data]) => ({
      dish,
      average: data.average,
      totalVotes: data.totalCount
    }));
  }

  return result;
};

const getDislikedDishesWeek = async () => {
  const weekStart = getWeekMondayISO();
  const snapshot = await dishStatistics.child(`weekly/weekOf_${weekStart}`).once("value");
  const stats = snapshot.val();
  if (!stats) return null;

  const result = {};

  for (const meal of Object.keys(stats)) {
    const dishes = Object.entries(stats[meal])
      .filter(([_, data]) => data.average < 3)   // 🔥 điều kiện < 3
      .sort((a, b) => a[1].average - b[1].average); // 🔥 sort tăng dần (tệ nhất lên trước)

    result[meal] = dishes.map(([dish, data]) => ({
      dish,
      average: data.average,
      totalVotes: data.totalCount
    }));
  }

  return result;
};


module.exports = {
  createMealPlan,
  saveDishRatings,
  getTopDishes,
  getDislikedDishes,
  getTopDishesWeek,
  getDislikedDishesWeek
};
