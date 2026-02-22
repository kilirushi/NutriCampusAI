const fs = require("fs");
const path = require("path");

const menuPath = path.join(__dirname, "../data/dining_hall_menu.json");

const getMenu = () => {
  try {
    const data = fs.readFileSync(menuPath, "utf-8");
    return JSON.parse(data); // chuyển từ JSON string → object
  } catch (err) {
    console.error("Error reading menu JSON:", err);
    return [];
  }
};

module.exports = { getMenu };
