
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();

exports.completeToday = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must sign in first."
    );
  }

  if (request.data?.challengeId !== "today") {
    throw new HttpsError(
      "invalid-argument",
      "Invalid challenge."
    );
  }

  const uid = request.auth.uid;

  const progressRef = db
    .collection("users")
    .doc(uid)
    .collection("progress")
    .doc("today");

  return db.runTransaction(async (transaction) => {
    const progressDoc = await transaction.get(progressRef);

    if (progressDoc.exists) {
      const progress = progressDoc.data();

      return {
        completed: true,
        points: progress.points,
        badgeId: progress.badgeId,
        alreadyCompleted: true
      };
    }

    transaction.set(progressRef, {
      completed: true,
      points: 10,
      badgeId: "first-quest",
      completedAt: FieldValue.serverTimestamp()
    });

    return {
      completed: true,
      points: 10,
      badgeId: "first-quest",
      alreadyCompleted: false
    };
  });
});

exports.askQuestCoach =
  require("./questCoach").askQuestCoach;