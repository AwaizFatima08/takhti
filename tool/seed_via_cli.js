// Seeds lessons + appConfig using the logged-in Firebase CLI account (no
// service-account key needed). Usage: node seed_via_cli.js
const path = require('path');
const fs = require('fs');
const FT = path.join(require('os').homedir(), '.npm-global/lib/node_modules/firebase-tools/lib');
const { requireAuth } = require(path.join(FT, 'requireAuth.js'));
const { getAccessToken } = require(path.join(FT, 'apiv2.js'));
const { getGlobalDefaultAccount } = require(path.join(FT, 'auth.js'));

const PROJECT = 'takhti-grow-homilabs';
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

function toValue(v) {
  if (v === null) return { nullValue: null };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'object') return { mapValue: { fields: toFields(v) } };
  return { stringValue: String(v) };
}
function toFields(o) { return Object.fromEntries(Object.entries(o).map(([k, v]) => [k, toValue(v)])); }

(async () => {
  const acct = getGlobalDefaultAccount();
  if (!acct) throw new Error('Run firebase login first');
  await requireAuth({ project: PROJECT, user: acct.user, tokens: acct.tokens });
  const token = await getAccessToken();
  const { lessons } = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'assets', 'lessons.json'), 'utf8'));
  const writes = lessons.map(({ id, ...data }) => ({
    update: { name: `projects/${PROJECT}/databases/(default)/documents/lessons/${id}`, fields: toFields(data) },
    updateTransforms: [{ fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }],
  }));
  writes.push({
    update: {
      name: `projects/${PROJECT}/databases/(default)/documents/appConfig/main`,
      fields: toFields({
        minSupportedBuild: 1,
        pilotLessonCount: lessons.length,
        privacyUrl: 'https://takhti.homilabs.org/grow/privacy.html',
        termsUrl: 'https://takhti.homilabs.org/grow/terms.html',
        deleteAccountUrl: 'https://takhti.homilabs.org/grow/delete-account.html',
      }),
    },
  });
  const res = await fetch(`${BASE}:commit`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ writes }),
  });
  const body = await res.json();
  if (!res.ok) { console.error(res.status, JSON.stringify(body).slice(0, 500)); process.exit(1); }
  console.log(`Committed ${writes.length} writes (${lessons.length} lessons + appConfig/main)`);
})().catch((e) => { console.error(e.message); process.exit(1); });
