// Writes assets/lessons.json and appConfig/main to Firestore (design 8.8).
// Usage (from tool/):
//   GOOGLE_APPLICATION_CREDENTIALS=../../takhti_grow-secrets/service-account.json node seed_lessons.js
// The service-account key comes from Firebase console → Project settings →
// Service accounts → Generate new private key. Never commit it (public repo).
// Bump contentVersion in lessons.json for every lesson you edit.
const fs = require('fs');
const path = require('path');
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp({ credential: applicationDefault(), projectId: 'takhti-grow-homilabs' });
const db = getFirestore();

async function main() {
  const file = path.join(__dirname, '..', 'assets', 'lessons.json');
  const { lessons } = JSON.parse(fs.readFileSync(file, 'utf8'));
  const batch = db.batch();
  for (const { id, ...data } of lessons) {
    if (data.keyIdea.length !== 3 || data.quiz.length !== 3) throw new Error(`${id}: needs 3 bullets and 3 questions`);
    batch.set(db.doc(`lessons/${id}`), { ...data, updatedAt: FieldValue.serverTimestamp() });
  }
  batch.set(db.doc('appConfig/main'), {
    minSupportedBuild: 1,
    pilotLessonCount: lessons.length,
    privacyUrl: 'https://takhti.homilabs.org/grow/privacy.html',
    termsUrl: 'https://takhti.homilabs.org/grow/terms.html',
    deleteAccountUrl: 'https://takhti.homilabs.org/grow/delete-account.html',
  }, { merge: true });
  await batch.commit();
  console.log(`Seeded ${lessons.length} lessons + appConfig/main`);
}

main().catch((e) => { console.error(e); process.exit(1); });
