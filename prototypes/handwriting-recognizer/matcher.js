// PROTOTYPE, throwaway. KanjiVG template matcher for drawn kanji.
// Shared by index.html (browser) and score.js (Node).
(function (root) {
  const K = 12;
  const STROKE_WINDOW = 2;
  const MISSING_STROKE_COST = 0.6;
  const REVERSED_STROKE_EXTRA = 0.08;

  function toPoints(flat) {
    const pts = [];
    for (let i = 0; i < flat.length; i += 2) pts.push([flat[i], flat[i + 1]]);
    return pts;
  }

  function length(pts) {
    let len = 0;
    for (let i = 1; i < pts.length; i++) len += Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]);
    return len;
  }

  function resample(pts, n) {
    if (pts.length === 1) return Array.from({ length: n }, () => pts[0].slice());
    const total = length(pts);
    if (total === 0) return Array.from({ length: n }, () => pts[0].slice());
    const step = total / (n - 1);
    const out = [pts[0].slice()];
    let acc = 0;
    let i = 1;
    let prev = pts[0];
    while (out.length < n - 1 && i < pts.length) {
      const cur = pts[i];
      const seg = Math.hypot(cur[0] - prev[0], cur[1] - prev[1]);
      if (acc + seg >= step && seg > 0) {
        const t = (step - acc) / seg;
        const q = [prev[0] + t * (cur[0] - prev[0]), prev[1] + t * (cur[1] - prev[1])];
        out.push(q);
        prev = q;
        acc = 0;
      } else {
        acc += seg;
        prev = cur;
        i++;
      }
    }
    while (out.length < n) out.push(pts[pts.length - 1].slice());
    return out;
  }

  // norm "bbox": fit the bounding box into the unit square, aspect kept, centred.
  // norm "moment": centre on the length-weighted centroid, scale by RMS radius.
  function normalize(strokes, norm) {
    const all = strokes.flat();
    if (norm === "moment") {
      let cx = 0, cy = 0;
      for (const p of all) { cx += p[0]; cy += p[1]; }
      cx /= all.length; cy /= all.length;
      let r = 0;
      for (const p of all) r += (p[0] - cx) ** 2 + (p[1] - cy) ** 2;
      r = Math.sqrt(r / all.length) || 1;
      const s = 0.25 / r;
      return strokes.map((st) => st.map((p) => [0.5 + (p[0] - cx) * s, 0.5 + (p[1] - cy) * s]));
    }
    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
    for (const p of all) {
      minX = Math.min(minX, p[0]); maxX = Math.max(maxX, p[0]);
      minY = Math.min(minY, p[1]); maxY = Math.max(maxY, p[1]);
    }
    const size = Math.max(maxX - minX, maxY - minY) || 1;
    const ox = (size - (maxX - minX)) / 2 - minX;
    const oy = (size - (maxY - minY)) / 2 - minY;
    return strokes.map((st) => st.map((p) => [(p[0] + ox) / size, (p[1] + oy) / size]));
  }

  // strokes: array of point arrays ([x, y] or [x, y, t]).
  function prepare(strokes, norm) {
    const sampled = strokes.map((st) => resample(st.map((p) => [p[0], p[1]]), K));
    return normalize(sampled, norm);
  }

  function strokeCost(a, b) {
    let fwd = 0, rev = 0;
    for (let i = 0; i < K; i++) {
      fwd += Math.hypot(a[i][0] - b[i][0], a[i][1] - b[i][1]);
      rev += Math.hypot(a[i][0] - b[K - 1 - i][0], a[i][1] - b[K - 1 - i][1]);
    }
    return Math.min(fwd / K, rev / K + REVERSED_STROKE_EXTRA);
  }

  // order "strict": stroke i is compared to template stroke i.
  // order "free": best one-to-one stroke assignment (Hungarian), so stroke-order mistakes still match.
  function charCost(input, template, order) {
    const n = input.length, m = template.length;
    const big = Math.max(n, m);
    if (order === "strict") {
      let cost = 0;
      for (let i = 0; i < Math.min(n, m); i++) cost += strokeCost(input[i], template[i]);
      return (cost + Math.abs(n - m) * MISSING_STROKE_COST) / big;
    }
    const matrix = [];
    for (let i = 0; i < big; i++) {
      const row = [];
      for (let j = 0; j < big; j++) {
        row.push(i < n && j < m ? strokeCost(input[i], template[j]) : MISSING_STROKE_COST);
      }
      matrix.push(row);
    }
    return hungarian(matrix) / big;
  }

  function hungarian(a) {
    const n = a.length;
    const u = new Float64Array(n + 1), v = new Float64Array(n + 1);
    const p = new Int32Array(n + 1), way = new Int32Array(n + 1);
    for (let i = 1; i <= n; i++) {
      p[0] = i;
      let j0 = 0;
      const minv = new Float64Array(n + 1).fill(Infinity);
      const used = new Uint8Array(n + 1);
      do {
        used[j0] = 1;
        const i0 = p[j0];
        let delta = Infinity, j1 = 0;
        for (let j = 1; j <= n; j++) {
          if (used[j]) continue;
          const cur = a[i0 - 1][j - 1] - u[i0] - v[j];
          if (cur < minv[j]) { minv[j] = cur; way[j] = j0; }
          if (minv[j] < delta) { delta = minv[j]; j1 = j; }
        }
        for (let j = 0; j <= n; j++) {
          if (used[j]) { u[p[j]] += delta; v[j] -= delta; } else minv[j] -= delta;
        }
        j0 = j1;
      } while (p[j0] !== 0);
      do { const j1 = way[j0]; p[j0] = p[j1]; j0 = j1; } while (j0);
    }
    let cost = 0;
    for (let j = 1; j <= n; j++) cost += a[p[j] - 1][j - 1];
    return cost;
  }

  function buildIndex(templates) {
    const index = [];
    for (const [char, flats] of Object.entries(templates)) {
      const strokes = flats.map(toPoints);
      index.push({ char, count: strokes.length, bbox: prepare(strokes, "bbox"), moment: prepare(strokes, "moment") });
    }
    return index;
  }

  function recognize(index, strokes, { norm = "bbox", order = "free", limit = 10 } = {}) {
    if (!strokes.length) return [];
    const input = prepare(strokes, norm);
    const results = [];
    for (const t of index) {
      if (Math.abs(t.count - input.length) > STROKE_WINDOW) continue;
      results.push({ char: t.char, cost: charCost(input, t[norm], order) });
    }
    results.sort((x, y) => x.cost - y.cost);
    return results.slice(0, limit);
  }

  const VARIANTS = [
    { name: "bbox + free order", norm: "bbox", order: "free" },
    { name: "bbox + strict order", norm: "bbox", order: "strict" },
    { name: "moment + free order", norm: "moment", order: "free" },
    { name: "moment + strict order", norm: "moment", order: "strict" },
  ];

  // samples: [{ target, strokes }]. Returns per-variant accuracy and the misses.
  function score(index, samples, variant) {
    const ranks = [];
    const misses = [];
    for (const s of samples) {
      const top = recognize(index, s.strokes, { norm: variant.norm, order: variant.order, limit: 10 });
      const rank = top.findIndex((r) => r.char === s.target) + 1;
      ranks.push(rank);
      if (rank !== 1) misses.push({ target: s.target, rank: rank || null, got: top.slice(0, 3).map((r) => r.char).join("") });
    }
    const within = (k) => ranks.filter((r) => r >= 1 && r <= k).length / (ranks.length || 1);
    return { variant: variant.name, n: ranks.length, top1: within(1), top5: within(5), top10: within(10), misses };
  }

  const api = { buildIndex, recognize, score, VARIANTS };
  root.Matcher = api;
  if (typeof module !== "undefined") module.exports = api;
})(typeof window !== "undefined" ? window : globalThis);
