// PROTOTYPE, throwaway. Scores a drawn test set against every matcher variant.
//   node prototypes/handwriting-recognizer/score.js testset.json
//   node prototypes/handwriting-recognizer/score.js --synthetic   (pipeline check only, not the verdict)
const fs = require("fs");
const path = require("path");
const vm = require("vm");
const Matcher = require("./matcher.js");

const sandbox = { window: {} };
vm.runInNewContext(fs.readFileSync(path.join(__dirname, "templates.js"), "utf8"), sandbox);
const { TEMPLATES, TEST_TARGETS } = sandbox.window;

function rng(seed) {
  return () => ((seed = (seed * 1664525 + 1013904223) >>> 0) / 4294967296);
}

function synthetic() {
  const rand = rng(42);
  return TEST_TARGETS.map((target) => {
    const sx = 0.8 + rand() * 0.4, sy = 0.8 + rand() * 0.4, shear = (rand() - 0.5) * 0.3;
    let strokes = TEMPLATES[target].map((flat) => {
      const pts = [];
      for (let i = 0; i < flat.length; i += 2) {
        const x = flat[i], y = flat[i + 1];
        pts.push([x * sx + y * shear + (rand() - 0.5) * 4, y * sy + (rand() - 0.5) * 4]);
      }
      return rand() < 0.1 ? pts.reverse() : pts;
    });
    if (strokes.length > 2 && rand() < 0.3) {
      const i = Math.floor(rand() * (strokes.length - 1));
      [strokes[i], strokes[i + 1]] = [strokes[i + 1], strokes[i]];
    }
    return { target, strokes };
  });
}

const arg = process.argv[2];
if (!arg) {
  console.error("usage: score.js <testset.json> | --synthetic");
  process.exit(1);
}
const samples = arg === "--synthetic" ? synthetic() : JSON.parse(fs.readFileSync(arg, "utf8")).samples;
const index = Matcher.buildIndex(TEMPLATES);
const pct = (x) => (x * 100).toFixed(1).padStart(5) + "%";

console.log(`${samples.length} samples${arg === "--synthetic" ? " (synthetic)" : ""}\n`);
console.log("variant                  top-1   top-5  top-10   ms/sample");
const results = [];
for (const variant of Matcher.VARIANTS) {
  const start = process.hrtime.bigint();
  const r = Matcher.score(index, samples, variant);
  const ms = Number(process.hrtime.bigint() - start) / 1e6 / samples.length;
  results.push(r);
  console.log(`${variant.name.padEnd(22)} ${pct(r.top1)}  ${pct(r.top5)}  ${pct(r.top10)}   ${ms.toFixed(1)}`);
}
// Fixed before any drawing, so picking the winner on the test set can't bias the verdict.
const primary = results[0];
console.log(`\nPrimary variant (fixed in advance): ${primary.variant}. The other rows are for reference only.`);
console.log(`Misses (target, rank in top 10 or -, top 3):`);
for (const m of primary.misses) console.log(`  ${m.target}  ${String(m.rank ?? "-").padStart(2)}  ${m.got}`);
