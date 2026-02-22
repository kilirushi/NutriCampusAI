require("dotenv").config(); // load env trước
const app = require("./app");
const fs = require("fs").promises;
const path = require("path");
const fetch = require("node-fetch"); // or use global fetch on Node >=18
const { getWeekMondayISO } = require("./utils/date.util");

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

async function fetchAndSaveMenu() {
  const apiUrl = process.env.MENU_API_URL;
  const outPath = path.join(__dirname, "data", "dining_hall_menu.json");

  try {
    if (!apiUrl) throw new Error("MENU_API_URL not set");
    const res = await fetch(apiUrl, { timeout: 15000 });
    if (!res.ok) throw new Error(`Fetch failed: ${res.status}`);
    const json = await res.json();
    await fs.writeFile(outPath, JSON.stringify(json, null, 2), "utf8");
    console.log("Menu updated from API for week:", getWeekMondayISO());
  } catch (err) {
    console.warn("Menu update failed, keeping existing menu:", err.message);
  }
}

function msUntilNextMonday() {
  const now = new Date();
  const day = now.getDay(); // 0 = Sun, 1 = Mon, ...
  let diff = (1 - day + 7) % 7;
  if (diff === 0) diff = 7; // next Monday if today is Monday
  const next = new Date(now);
  next.setDate(now.getDate() + diff);
  next.setHours(0, 0, 0, 0);
  return next - now;
}

function scheduleWeeklyUpdate() {
  const firstDelay = msUntilNextMonday();
  setTimeout(() => {
    fetchAndSaveMenu();
    // then run every 7 days
    setInterval(fetchAndSaveMenu, 7 * 24 * 60 * 60 * 1000);
  }, firstDelay);
}

// call on startup
scheduleWeeklyUpdate();
