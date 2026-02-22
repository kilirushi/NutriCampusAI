const db = require("../config/firebase");
const logger = require("../utils/logger.util");

const FIREBASE_ROOT = process.env.FIREBASE_ROOT || "defaultRoot";

const mealPlanRef = db.ref(`${FIREBASE_ROOT}/mealPlans`);
const dishStatistics = db.ref(`${FIREBASE_ROOT}/dishStatistics`);

// Helper methods
const mealPlanModel = {
  // Create new meal plan
  async create(userId, mealPlanData) {
    try {
      const newRef = mealPlanRef.child(userId).push();
      await newRef.set({ ...mealPlanData, createdAt: Date.now() });
      return { id: newRef.key, ...mealPlanData };
    } catch (err) {
      logger.error("Create meal plan error", { error: err.message });
      throw err;
    }
  },

  // Get meal plans by user
  async getByUserId(userId) {
    try {
      const snapshot = await mealPlanRef.child(userId).once("value");
      return snapshot.val() || {};
    } catch (err) {
      logger.error("Get meal plans error", { error: err.message });
      throw err;
    }
  },

  // Update meal plan
  async update(userId, planId, updates) {
    try {
      await mealPlanRef.child(`${userId}/${planId}`).update(updates);
      return { id: planId, ...updates };
    } catch (err) {
      logger.error("Update meal plan error", { error: err.message });
      throw err;
    }
  },

  // Record dish rating
  async rateDish(dishId, rating, feedback) {
    try {
      const statsRef = dishStatistics.child(dishId);
      await statsRef.transaction((current) => {
        const data = current || { totalRating: 0, count: 0, feedbacks: [] };
        data.totalRating += rating;
        data.count += 1;
        data.avgRating = data.totalRating / data.count;
        if (feedback) data.feedbacks = [...(data.feedbacks || []), feedback];
        return data;
      });
    } catch (err) {
      logger.error("Rate dish error", { error: err.message });
      throw err;
    }
  },

  // Get top dishes
  async getTopDishes(limit = 10) {
    try {
      const snapshot = await dishStatistics.orderByChild("avgRating").limitToLast(limit).once("value");
      return snapshot.val() || {};
    } catch (err) {
      logger.error("Get top dishes error", { error: err.message });
      throw err;
    }
  },
};

module.exports = { mealPlanRef, dishStatistics, mealPlanModel };
