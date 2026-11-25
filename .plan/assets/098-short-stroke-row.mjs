// Throwaway: renders variant C (dot + arrow beside stroke) on the shortest strokes in two draw orders, as a static SVG.
// Cell is 160 pt with 12 pt padding, a 136 pt drawing square, as on a 393 pt iPhone.
// Usage: node 098-short-stroke-row.mjs > out.svg && rsvg-convert -z 2 out.svg -o 098-short-stroke-row.png
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const html = readFileSync(fileURLToPath(new URL("./098-direction-prototype.html", import.meta.url)), "utf8");
const DATA = JSON.parse(html.match(/const DATA=(\{.*?\});\n/s)[1]);
for (const ch of ["鹽"]) {
  const file = new URL(`../../Dataset/AppOnly/stroke-order/${ch.codePointAt(0).toString(16).padStart(5, "0")}.svg`, import.meta.url);
  DATA[ch] = { paths: [...readFileSync(fileURLToPath(file), "utf8").matchAll(/\bd="([^"]+)"/g)].map((m) => m[1]) };
}
const CELLS = [["鹽", 15], ["鬱", 18], ["鬱", 19], ["鬱", 20], ["鬱", 21], ["議", 0], ["心", 2], ["十", 1]];
const ORDERS = [["drafted: markers above stroke", false], ["fix: current stroke above dot", true]];
const MODES = {
  light: { sunken: "#eae2d1", ink: "#1f1b16", muted: "#5e5548", hair: "#d9cfbc", mark: "#b8321d", raised: "#fbf7ee" },
  dark: { sunken: "#0f0d0a", ink: "#efe8d8", muted: "#a89f8e", hair: "#35302a", mark: "#e8603f", raised: "#1f1c16" },
};

function flatten(d) {
  const toks = d.match(/[a-zA-Z]|-?\d*\.?\d+(?:e-?\d+)?/g);
  const pts = [];
  let i = 0, cmd = "", x = 0, y = 0, lcx = 0, lcy = 0;
  const num = () => parseFloat(toks[i++]);
  const cubic = (x1, y1, x2, y2, x3, y3) => {
    for (let k = 1; k <= 64; k++) {
      const t = k / 64, u = 1 - t;
      pts.push([u*u*u*x + 3*u*u*t*x1 + 3*u*t*t*x2 + t*t*t*x3, u*u*u*y + 3*u*u*t*y1 + 3*u*t*t*y2 + t*t*t*y3]);
    }
    lcx = x2; lcy = y2; x = x3; y = y3;
  };
  while (i < toks.length) {
    if (/[a-zA-Z]/.test(toks[i])) cmd = toks[i++];
    const rel = cmd === cmd.toLowerCase(), ox = rel ? x : 0, oy = rel ? y : 0;
    switch (cmd.toLowerCase()) {
      case "m": x = num() + ox; y = num() + oy; pts.push([x, y]); lcx = x; lcy = y; cmd = rel ? "l" : "L"; break;
      case "l": x = num() + ox; y = num() + oy; pts.push([x, y]); lcx = x; lcy = y; break;
      case "c": cubic(num()+ox, num()+oy, num()+ox, num()+oy, num()+ox, num()+oy); break;
      case "s": { const rx = 2*x - lcx, ry = 2*y - lcy; cubic(rx, ry, num()+ox, num()+oy, num()+ox, num()+oy); break; }
      case "z": i = toks.length; break;
      default: throw new Error("unsupported " + cmd);
    }
  }
  return pts;
}

function dirOf(d) {
  const pts = flatten(d);
  let L = 0, q = pts[pts.length - 1], hit = false;
  for (let k = 1; k < pts.length; k++) {
    const seg = Math.hypot(pts[k][0] - pts[k-1][0], pts[k][1] - pts[k-1][1]);
    if (!hit && L + seg >= 10) { const f = (10 - L) / seg; q = [pts[k-1][0] + f*(pts[k][0]-pts[k-1][0]), pts[k-1][1] + f*(pts[k][1]-pts[k-1][1])]; hit = true; }
    L += seg;
  }
  const s = pts[0], dx = q[0] - s[0], dy = q[1] - s[1], m = Math.hypot(dx, dy) || 1;
  return { s, ux: dx / m, uy: dy / m, L };
}

const f = (n) => n.toFixed(2);
function chevron(cx, cy, ux, uy, arm, w) {
  const a = 0.75, px = -uy, py = ux;
  const p1 = [cx - arm*(ux*Math.cos(a) - px*Math.sin(a)), cy - arm*(uy*Math.cos(a) - py*Math.sin(a))];
  const p2 = [cx - arm*(ux*Math.cos(a) + px*Math.sin(a)), cy - arm*(uy*Math.cos(a) + py*Math.sin(a))];
  const d = `M${f(p1[0])},${f(p1[1])}L${f(cx)},${f(cy)}L${f(p2[0])},${f(p2[1])}`;
  return [["sunken", w + 3], ["mark", w]].map(([c, sw]) =>
    `<path d="${d}" fill="none" stroke="{${c}}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round"/>`).join("");
}

function cell(ch, step, strokeOverDot) {
  const paths = DATA[ch].paths;
  const order = paths.map((_, i) => i).filter((i) => i !== step).concat(step);
  const stroke = (i) => `<path d="${paths[i]}" fill="none" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" stroke="{${i < step ? "muted" : i > step ? "hair" : "ink"}}"/>`;
  let out = order.slice(0, -1).map(stroke).join("");
  const { s, ux, uy, L } = dirOf(paths[step]);
  const dot = `<circle cx="${f(s[0])}" cy="${f(s[1])}" r="6" fill="{sunken}"/><circle cx="${f(s[0])}" cy="${f(s[1])}" r="4.5" fill="{mark}"/>`;
  out += strokeOverDot ? dot + stroke(step) : stroke(step) + dot;
  const px = uy, py = -ux, off = 8;
  const x1 = s[0] + px*off + ux*2, y1 = s[1] + py*off + uy*2, x2 = x1 + ux*11, y2 = y1 + uy*11;
  for (const [c, w] of [["sunken", 4.8], ["mark", 1.8]])
    out += `<path d="M${f(x1)},${f(y1)}L${f(x2)},${f(y2)}" stroke="{${c}}" stroke-width="${w}" stroke-linecap="round"/>`;
  out += chevron(x2, y2, ux, uy, 4, 1.8);
  return { out, label: `${ch} s${step + 1}  ${L.toFixed(1)}u` };
}

const CELL = 160, PAD = 12, GAP = 8, LBL = 18, ROWH = CELL + LBL + 8;
const ROWS = Object.entries(MODES).flatMap(([name, c]) => ORDERS.map(([oname, over]) => [`${name}, ${oname}`, c, over]));
const W = CELLS.length * (CELL + GAP) + GAP, H = ROWS.length * (ROWH + 24) + 8;
let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" font-family="sans-serif" font-size="11">`;
ROWS.forEach(([name, c, over], r) => {
  const oy = 4 + r * (ROWH + 24);
  let row = `<rect x="0" y="${oy}" width="${W}" height="${ROWH + 20}" rx="12" fill="{raised}"/><text x="${GAP}" y="${oy + 14}" fill="{ink}" font-weight="bold">${name}</text>`;
  CELLS.forEach(([ch, step], k) => {
    const x = GAP + k * (CELL + GAP), y = oy + 20;
    const { out, label } = cell(ch, step, over);
    const scale = (CELL - 2 * PAD) / 109;
    row += `<rect x="${x}" y="${y}" width="${CELL}" height="${CELL}" rx="10" fill="{sunken}"/>`;
    row += `<g transform="translate(${x + PAD},${y + PAD}) scale(${scale.toFixed(4)})">${out}</g>`;
    row += `<text x="${x + 4}" y="${y + CELL + 13}" fill="{ink}">${label}</text>`;
  });
  svg += row.replace(/\{(\w+)\}/g, (_, k) => c[k]);
});
process.stdout.write(svg + "</svg>\n");
