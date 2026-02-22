# 🌱 NutriCampusAI

*An AI-assisted meal recommendation app for campus students based on BMI and food preferences.*

---

## 🚀 Introduction
NutriCampusAI is a mobile and backend application that helps students make smarter food choices. Users can:  

- Calculate their BMI using height (inches) and weight (pounds)  
- Receive personalized meal suggestions aligned with the campus dining hall menu  
- Rate meals from 1–5 stars  
- Reduce food waste by choosing meals that suit their needs  

All data is stored securely in **Firebase Realtime Database**.

---

## 🛠 Features
- BMI calculation with formula:  

$$
BMI = \frac{weight \times 703}{height^2}
$$

- Real-time meal recommendations  
- Meal rating system  
- Backend built with **Node.js**  
- Real-time database using **Firebase Realtime Database**  
- Optional mobile app for iOS/Android  

---

## 📋 Requirements
- Node.js >= 18  
- npm or yarn  
- Firebase account (Realtime Database)  
- iOS simulator or real device  

---

## ⚡ Installation

### 1. Clone the repository
```bash
git clone https://github.com/your-username/NutriCampusAI.git
cd NutriCampusAI
```

### 2. Install backend dependencies
```bash
cd backend/nutri-campus-ai
npm install
```
### 3. Configure Firebase
Create a Firebase project with Realtime Database.
Download firebaseConfig.json from your Firebase console.
Place the file in backend/config/ and ensure it contains your project credentials.
