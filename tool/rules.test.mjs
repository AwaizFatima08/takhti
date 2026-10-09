// Firestore rules tests (design 8.4). Run: npm run test:rules (from tool/).
import { test, before, after, beforeEach } from 'node:test';
import fs from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, query, where, getDocs, serverTimestamp } from 'firebase/firestore';

let env;
const userDoc = (extra = {}) => ({
  displayName: 'Homi', ageConfirmed18: true, termsVersion: '2026-10', createdAt: serverTimestamp(), ...extra,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-takhti',
    firestore: { rules: fs.readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8085 },
  });
});
after(() => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'lessons/l1'), { published: true, order: 1 });
    await setDoc(doc(db, 'lessons/draft'), { published: false, order: 9 });
    await setDoc(doc(db, 'appConfig/main'), { minSupportedBuild: 1 });
    await setDoc(doc(db, 'users/bob'), { displayName: 'Bob', ageConfirmed18: true, createdAt: 1 });
    await setDoc(doc(db, 'feedback/f-bob'), { uid: 'bob', rating: 4, comment: '' });
  });
});

const alice = () => env.authenticatedContext('alice').firestore();
const anon = () => env.unauthenticatedContext().firestore();

test('published lessons and appConfig are public; drafts and writes are not', async () => {
  await assertSucceeds(getDoc(doc(anon(), 'lessons/l1')));
  await assertSucceeds(getDocs(query(collection(anon(), 'lessons'), where('published', '==', true))));
  await assertFails(getDoc(doc(anon(), 'lessons/draft')));
  await assertFails(setDoc(doc(alice(), 'lessons/l1'), { published: true }));
  await assertSucceeds(getDoc(doc(anon(), 'appConfig/main')));
  await assertFails(setDoc(doc(alice(), 'appConfig/main'), { minSupportedBuild: 0 }));
});

test('user doc needs 18+ and a valid name; only the owner reads it', async () => {
  await assertFails(setDoc(doc(alice(), 'users/alice'), userDoc({ ageConfirmed18: false })));
  await assertFails(setDoc(doc(alice(), 'users/alice'), userDoc({ displayName: 'A' })));
  await assertFails(setDoc(doc(alice(), 'users/bob2'), userDoc()));
  await assertSucceeds(setDoc(doc(alice(), 'users/alice'), userDoc()));
  await assertFails(getDoc(doc(alice(), 'users/bob')));
  await assertSucceeds(updateDoc(doc(alice(), 'users/alice'), { reminderLessonTime: '08:00', currentStreak: 2 }));
  await assertFails(updateDoc(doc(alice(), 'users/alice'), { ageConfirmed18: false }));
  await assertFails(updateDoc(doc(alice(), 'users/alice'), { createdAt: 5 }));
  await assertFails(updateDoc(doc(alice(), 'users/alice'), { reminderLessonTime: 'soon' }));
});

test('reflections: create once, never edit, note ≤ 500', async () => {
  await setDoc(doc(alice(), 'users/alice'), userDoc());
  const r = doc(alice(), 'users/alice/reflections/l1');
  await assertFails(setDoc(r, { actionDone: 'maybe', note: '' }));
  await assertFails(setDoc(r, { actionDone: 'yes', note: 'x'.repeat(501) }));
  await assertSucceeds(setDoc(r, { actionDone: 'partly', note: 'ok' }));
  await assertFails(setDoc(r, { actionDone: 'yes', note: 'changed' }));
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(), 'users/alice/reflections/l1')));
  await assertSucceeds(deleteDoc(r));
});

test('feedback: own uid only, rating 1–5, empty comment ok, owner can find and delete', async () => {
  await assertFails(addDoc(collection(alice(), 'feedback'), { uid: 'bob', rating: 5, comment: '' }));
  await assertFails(addDoc(collection(alice(), 'feedback'), { uid: 'alice', rating: 6, comment: '' }));
  await assertFails(addDoc(collection(anon(), 'feedback'), { uid: 'alice', rating: 5, comment: '' }));
  const f = await assertSucceeds(addDoc(collection(alice(), 'feedback'), { uid: 'alice', rating: 5, comment: '' }));
  await assertSucceeds(getDocs(query(collection(alice(), 'feedback'), where('uid', '==', 'alice'))));
  await assertFails(getDocs(collection(alice(), 'feedback')));
  await assertFails(deleteDoc(doc(alice(), 'feedback/f-bob')));
  await assertSucceeds(deleteDoc(f));
});
