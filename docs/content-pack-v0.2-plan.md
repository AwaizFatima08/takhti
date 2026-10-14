# Content Pack v0.2 — 10 more lessons (plan)

Status: lessons drafted and tested on the emulator build, 14 Oct 2026; awaiting Adeel. Source: Takhti playlist "Power of Neuroplasticity"
(PLuXb_rB1a9tuP3dl_PI_7K4s8V0-LDMSp, 35 videos). Same workflow as v0.1:
Claude drafts from the videos' auto-captions, **Adeel reviews wording and clip
times**, then the lessons go to live Firestore and the next build.

## Lessons 5–14 (drafted 14 Oct 2026)

Transcribed locally with Whisper (large-v3-turbo, Urdu) from MP4s Homi
downloaded — YouTube rate-limited caption requests. Transcripts are in
`docs/captions/` (kept out of git; included in backups).

| # | Lesson | Video | Clip |
|---|---|---|---|
| 5 | You can change your brain | Rewire Your Brain, Ep 1 (RUppA4oHH6U) | 0:24–1:18 |
| 6 | Use it or lose it | Third Rule of Neuroplasticity (g2uvJxbna7c) | 4:32–6:48 |
| 7 | A memory is a connection | Learning Memory and Neuroplasticity (85s4OSS07jQ) | 3:29–4:50 |
| 8 | Step out of your comfort zone | Out of Comfort Zone, Ep 6 (K4fB-blb5qE) | 0:15–1:56 |
| 9 | Make a new habit stick | Making New Habits Permanent, Ep 12 (N1ltcjrHzuc) | 0:50–3:32 |
| 10 | Self-control in baby steps | Exercising Self Control, Ep 14 (pOX3AyLphBo) | 2:20–4:50 |
| 11 | Write it down | Exercises Which Can Change Brain Structure, Ep 10 (TR1W_aLbNAw) | 10:07–11:31 |
| 12 | Your brain is social | Ten Social Exercises for Brain, Ep 8 (IJrPJFvg3Bc) | 2:08–3:33 |
| 13 | Reframe the memory | Reframing, Ep 18 (GBykmo7rbes) | 3:14–5:58 |
| 14 | The chemistry of thank you | Molecules of Gratitude, Ep 8b (McrVI1A2Oyw) | 3:10–5:08 |

Left out of the lesson text on purpose (L9): the videos' claims about
depression, anxiety, pain relief, therapy, Alzheimer's and dementia.
Still available for later: Does the Brain Grow New Neurons? (Ep 3),
Enriched Environments (Ep 5), Gap Learning Effect (Ep 20), Napping (Ep 22).

## App changes for the build (v1.1.0, build 3)

- `assets/lessons.json`: lessons 5–14 (ids `l05-…` to `l14-…`, `order` 5–14,
  `contentVersion` 1), same shape as lessons 1–4.
- No logic change needed: unlocks, Today and streak already work for any
  number of lessons. Users who finished the 4-lesson pilot get Lesson 5 the
  day the new lessons are seeded.
- Wording: "Pilot — N lessons" already uses the count; the store listing and
  `web/grow/index.html` still say "four lessons" — update both.
- Tests: bundled-lesson check expects 14 lessons.
- Seeding live Firestore makes the lessons appear in v1.0.1 immediately (the
  app reads lessons from Firestore) — **only after Adeel approves**.
