// meal_plan.js
// Node 18+ (built-in fetch)
const fs = require("fs/promises");
const path = require("path");

const BASE =
  "https://api.elevate-dxp.com/api/mesh/c087f756-cc72-4649-a36f-3a41b700c519/graphql";
const OUTPUT_PATH = path.join(__dirname, "..", "data", "dining_hall.json");

const HEADERS = {
  accept: "*/*",
  "accept-language": "en-US,en;q=0.9",
  "aem-elevate-clientpath": "ch/uncp/en",
  "content-type": "application/json",
  "magento-customer-group": "b6589fc6ab0dc82cf12099d1c2d40ab994e8410c",
  "magento-store-code": "ch_uncp",
  "magento-store-view-code": "ch_uncp_en",
  "magento-website-code": "ch_uncp",
  origin: "https://uncp.mydininghub.com",
  referer: "https://uncp.mydininghub.com/",
  store: "ch_uncp_en",
  "user-agent": "Mozilla/5.0",
  "x-api-key": "ElevateAPIProd",
};

const QUERY_LOCATION_RECIPES = `
query getLocationRecipes($campusUrlKey:String!,$locationUrlKey:String!,$date:String!,$mealPeriod:Int,$viewType:Commerce_MenuViewType!){
  getLocationRecipes(
    campusUrlKey:$campusUrlKey
    locationUrlKey:$locationUrlKey
    date:$date
    mealPeriod:$mealPeriod
    viewType:$viewType
  ){
    products{
      items{ sku name }
    }
    locationRecipesMap{
      dateSkuMap{
        date
        stations{
          id
          skus{
            simple
            configurable{ sku variants }
          }
        }
      }
    }
  }
}
`.trim();

const STOP_WORDS = [
  "ketchup",
  "mustard",
  "mayonnaise",
  "mayo",
  "salt",
  "pepper",
  "sugar",
  "water",
  "ice",
  "lemon",
  "lime",
  "hot sauce",
  "sriracha",
  "tabasco",
  "soy sauce",
  "vinegar",
  "ranch",
  "italian dressing",
  "vinaigrette",
  "dressing",
  "napkin",
  "utensil",
  "fork",
  "spoon",
  "knife",
  "seeds",
  "beans",
  "dressing",
  "orange",
  "pineapple",
  "apple",
  "milk",
];

function isUnimportant(name) {
  const n = name.toLowerCase().trim();

  // exact match
  if (STOP_WORDS.includes(n)) return true;

  // contains match (good for "Ketchup Packet", "Ice Water", etc.)
  if (STOP_WORDS.some((w) => n.includes(w))) return true;

  return false;
}

function filterMenuItems(names) {
  return names.filter((n) => n && !isUnimportant(n));
}

// ---- YOU MUST SET THESE (see getMealPeriods below) ----
const MEAL_PERIODS = {
  Breakfast: 10,
  Lunch: 25,
  Dinner: 16,
};

function baseSku(sku) {
  const parts = sku.split("_");
  const last = parts[parts.length - 1];
  if (parts.length > 1 && /^\d+$/.test(last)) {
    return parts.slice(0, -1).join("_");
  }
  return sku;
}

async function fetchLocationRecipes(dateStr, mealPeriod) {
  const variables = {
    campusUrlKey: "campus",
    locationUrlKey: "the-hall",
    date: dateStr,
    mealPeriod,
    viewType: "DAILY",
  };

  const url = new URL(BASE);
  url.searchParams.set("query", QUERY_LOCATION_RECIPES);
  url.searchParams.set("operationName", "getLocationRecipes");
  url.searchParams.set("variables", JSON.stringify(variables));

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30_000);

  try {
    const res = await fetch(url, {
      method: "GET",
      headers: HEADERS,
      signal: controller.signal,
    });

    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new Error(`HTTP ${res.status} ${res.statusText} ${text}`);
    }

    const payload = await res.json();
    if (payload?.errors?.length) {
      throw new Error(`GraphQL errors: ${JSON.stringify(payload.errors)}`);
    }

    return payload.data.getLocationRecipes;
  } finally {
    clearTimeout(timeout);
  }
}

function skuNameMap(glr) {
  const items = glr?.products?.items ?? [];
  const map = {};
  for (const it of items) {
    if (it?.sku && it?.name) map[it.sku] = it.name;
  }
  return map;
}

function extractMenuSkus(glr) {
  const dateSkuMap = glr?.locationRecipesMap?.dateSkuMap ?? [];
  const skus = [];

  for (const day of dateSkuMap) {
    for (const st of day?.stations ?? []) {
      const s = st?.skus ?? {};
      skus.push(...(s.simple ?? []));

      for (const c of s.configurable ?? []) {
        if (c?.sku) skus.push(c.sku);
        skus.push(...(c?.variants ?? []));
      }
    }
  }

  // de-dupe preserve order
  const seen = new Set();
  const out = [];
  for (const sku of skus) {
    if (sku && !seen.has(sku)) {
      seen.add(sku);
      out.push(sku);
    }
  }
  return out;
}

function resolveNames(menuSkus, skuToName) {
  const out = [];
  const seen = new Set();

  for (const sku of menuSkus) {
    const name = skuToName[sku] ?? skuToName[baseSku(sku)];
    if (name && !seen.has(name)) {
      seen.add(name);
      out.push(name);
    }
  }
  return out;
}

function mealPeriodsForDate(d) {
  // JS: Sunday=0 ... Saturday=6
  const day = d.getDay();
  const isWeekend = day === 0 || day === 6;
  if (isWeekend) {
    // use Brunch in Lunch slot
    return { Breakfast: 10, Lunch: 13, Dinner: 16 };
  }
  return { Breakfast: 10, Lunch: 25, Dinner: 16 };
}

function toIsoDate(d) {
  // Keep it simple (local time): YYYY-MM-DD
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${dd}`;
}

function dayName(d) {
  return d.toLocaleDateString("en-US", { weekday: "long" });
}

async function build7Days(startDate) {
  const weekly = {};

  for (let i = 0; i < 7; i++) {
    const d = new Date(startDate);
    d.setDate(startDate.getDate() + i);

    const dn = dayName(d);
    const dateStr = toIsoDate(d);
    weekly[dn] = {};

    const periods = mealPeriodsForDate(d);
    for (const [mealName, mp] of Object.entries(periods)) {
      if (!mp) {
        weekly[dn][mealName] = [];
        continue;
      }

      const glr = await fetchLocationRecipes(dateStr, mp);
      const skuToName = skuNameMap(glr);
      const menuSkus = extractMenuSkus(glr);
      weekly[dn][mealName] = filterMenuItems(resolveNames(menuSkus, skuToName));
    }
  }

  return weekly;
}

// ---- OPTIONAL: print meal period IDs so you can set MEAL_PERIODS correctly ----
const QUERY_LOCATION = `
query getLocation($campusUrlKey:String!,$locationUrlKey:String!){
  getLocation(campusUrlKey:$campusUrlKey locationUrlKey:$locationUrlKey){
    commerceAttributes{ meal_periods{ id name position } }
  }
}
`.trim();

async function getMealPeriods() {
  const variables = { campusUrlKey: "campus", locationUrlKey: "the-hall" };

  const url = new URL(BASE);
  url.searchParams.set("query", QUERY_LOCATION);
  url.searchParams.set("operationName", "getLocation");
  url.searchParams.set("variables", JSON.stringify(variables));

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30_000);

  try {
    const res = await fetch(url, {
      method: "GET",
      headers: HEADERS,
      signal: controller.signal,
    });

    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new Error(`HTTP ${res.status} ${res.statusText} ${text}`);
    }

    const payload = await res.json();
    if (payload?.errors?.length) {
      throw new Error(`GraphQL errors: ${JSON.stringify(payload.errors)}`);
    }

    return payload.data.getLocation.commerceAttributes.meal_periods;
  } finally {
    clearTimeout(timeout);
  }
}

// ------------------ main ------------------
(async () => {
  try {
    const weekly = await build7Days(new Date());

    // Convert to formatted JSON string
    const output = JSON.stringify(weekly, null, 2);

    // Write to src/data/dining_hall.json so the service reads the same file.
    await fs.writeFile(OUTPUT_PATH, output, "utf8");

    console.log("Saved to dining_hall.json successfully.");
  } catch (err) {
    console.error(err);
    process.exitCode = 1;
  }
})();
