# NutriCampusAI

AI-powered meal planning and dish-rating system for campus dining.

This repository contains:

- A Node.js backend API that generates weekly meal plans, stores ratings in Firebase, and serves an admin dashboard.
- An iOS SwiftUI app where students generate meal plans and rate dishes.

## What It Does

- Generates a 7-day meal plan from student height/weight using an LLM (Ollama + `llama3.2`).
- Uses dining menu data from local JSON and weekly API refresh.
- Lets students rate dishes by meal/day.
- Aggregates dish ratings globally and weekly.
- Shows top and disliked dishes in a web dashboard.

## Repository Structure

```text
NutriCampusAI/
  source/
    backend/
      nutri-campus-ai/         # Node.js backend
    frontend/
      Mobile/
        iOS/
          ios-nutri-campus-ai/ # SwiftUI iOS app
```

## Prerequisites

Install these before running:

1. Node.js 18+ and npm
2. Ollama (for AI meal plan generation)
3. Xcode 15+ (if you want to run the iOS app)
4. Firebase Realtime Database project + service account key JSON

## Backend Setup (Node.js)

### 1. Go to the backend folder

```powershell
cd source/backend/nutri-campus-ai
```

### 2. Install dependencies

```powershell
npm install
```

### 3. Add Firebase service account key

The backend expects this file:

`source/backend/nutri-campus-ai/serviceAccountKey.json`

The file is gitignored, so you must add your own key from Firebase Console.

### 4. Create `.env`

Create `source/backend/nutri-campus-ai/.env` with:

```env
PORT=3000
FIREBASE_ROOT=defaultRoot
MENU_API_URL=https://your-menu-api-endpoint
```

Notes:

- `PORT`: API server port.
- `FIREBASE_ROOT`: root path in Realtime Database.
- `MENU_API_URL`: used by weekly menu refresh in `src/server.js`.

### 5. Install and prepare Ollama

Install Ollama, then pull the model used by backend:

```powershell
ollama pull llama3.2
```

The backend calls:

```text
ollama run llama3.2
```

### 6. Run backend

Development:

```powershell
npm run dev
```

Production:

```powershell
npm start
```

Server starts on:

`http://localhost:3000`

## Admin Dashboard

Open:

`http://localhost:3000/`

It displays:

- Top dishes (all-time)
- Disliked dishes (all-time)
- Top dishes (this week)
- Disliked dishes (this week)

## iOS App Setup (SwiftUI)

### 1. Open the project

Open:

`source/frontend/Mobile/iOS/ios-nutri-campus-ai/ios-nutri-campus-ai.xcodeproj`

### 2. Configure API base URL

In `source/frontend/Mobile/iOS/ios-nutri-campus-ai/ios-nutri-campus-ai/API/APIService.swift`:

- Simulator: `http://localhost:3000/api/mealplan`
- Physical iPhone: use your computer LAN IP, for example `http://192.168.1.20:3000/api/mealplan`

Phone and computer must be on the same network.

### 3. Run from Xcode

- Select target `ios-nutri-campus-ai`
- Choose simulator/device
- Press Run

## API Endpoints

Base: `http://localhost:3000/api/mealplan`

1. `POST /generate`
   Request body:

```json
{
  "student_id": "student-123",
  "height_cm": 175,
  "weight_kg": 70
}
```

2. `POST /rate-dish`
   Request body:

```json
{
  "student_id": "student-123",
  "week_start": "2026-02-16",
  "day": "Monday",
  "ratings": {
    "Breakfast": {
      "Oatmeal": 5
    },
    "Lunch": {
      "Chicken Salad": 4
    }
  }
}
```

3. `GET /top-dishes`

## Menu Data Notes

- Fallback menu file: `source/backend/nutri-campus-ai/src/data/dining_hall_menu.json`
- Generated menu file: `source/backend/nutri-campus-ai/src/data/dining_hall.json`
- Menu generation script: `source/backend/nutri-campus-ai/src/data/meal_plan.js`

Manual run:

```powershell
cd source/backend/nutri-campus-ai
node src/data/meal_plan.js
```

## Troubleshooting

1. `Cannot find module 'serviceAccountKey.json'`

- Add `serviceAccountKey.json` to `source/backend/nutri-campus-ai/`.

2. Meal generation fails

- Confirm Ollama is installed.
- Confirm `llama3.2` is pulled (`ollama pull llama3.2`).
- Confirm Ollama is reachable from your shell.

3. iOS app cannot connect to backend

- Ensure backend is running.
- Use `localhost` for simulator.
- Use LAN IP for physical device.
- Ensure firewall allows incoming connections on port `3000`.

4. Dashboard shows no dishes

- No ratings have been submitted yet, or Firebase paths/config are mismatched.
- Verify `FIREBASE_ROOT` matches the data location used by your app/backend.

5. `Cannot find module 'node-fetch'`

- Run `npm install node-fetch@2` inside `source/backend/nutri-campus-ai`.

## Team

Erica, Hoa, Son, Dakota
