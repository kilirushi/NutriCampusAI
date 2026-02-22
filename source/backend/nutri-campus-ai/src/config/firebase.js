const admin = require("firebase-admin");
const serviceAccount = require("../../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://admob-app-id-2571998431.firebaseio.com"
});

const db = admin.database();

module.exports = db;
