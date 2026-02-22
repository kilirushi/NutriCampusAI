const db = require("../config/firebase");

const FIREBASE_ROOT = process.env.FIREBASE_ROOT || "defaultRoot";

const mealPlanRef = db.ref(`${FIREBASE_ROOT}/mealPlans`);
const dishStatistics = db.ref(`${FIREBASE_ROOT}/dishStatistics`);


module.exports = { mealPlanRef,dishStatistics };
