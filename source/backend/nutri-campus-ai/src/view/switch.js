// Simple view switcher (no frameworks)
const pageTitle = document.getElementById("pageTitle");

const navHome = document.getElementById("nav-home");
const navMealPlans = document.getElementById("nav-mealplans");
const navRates = document.getElementById("nav-rates");
const navReports = document.getElementById("nav-reports");

const viewHome = document.getElementById("view-home");
const viewRates = document.getElementById("view-rates");

const sideLinks = [navMealPlans, navRates, navReports];

function setActiveLink(activeEl) {
  sideLinks.forEach((a) => a.classList.remove("is-active"));
  if (activeEl) activeEl.classList.add("is-active");
}

function showView(which) {
  // hide all views
  [viewHome, viewRates].forEach((v) => v.classList.remove("is-active"));

  if (which === "rates") {
    viewRates.classList.add("is-active");
    pageTitle.textContent = "Rates";
    setActiveLink(navRates);
  } else {
    viewHome.classList.add("is-active");
    pageTitle.textContent = "Admin Dashboard";
    setActiveLink(navMealPlans);
  }
}

// Click handlers
navHome.addEventListener("click", (e) => {
  e.preventDefault();
  showView("home");
});
navMealPlans.addEventListener("click", (e) => {
  e.preventDefault();
  showView("home");
});
navRates.addEventListener("click", (e) => {
  e.preventDefault();
  showView("rates");
});

// Reports doesn't switch cards in this simple mock—kept for layout.
navReports.addEventListener("click", (e) => {
  e.preventDefault();
  pageTitle.textContent = "Reports";
  setActiveLink(navReports);
  // keep showing whatever view was last active
});
