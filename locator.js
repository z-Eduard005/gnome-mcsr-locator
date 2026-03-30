const fs = require('fs');
const path = require('path');
const { execSync, exec } = require('child_process');

// --- CONFIG & STATE ---
const FILE_PATH = path.join(__dirname, 'coords.txt');
const REGEX = /\/execute in minecraft:overworld run tp @s (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*)/;

let points = [];
let lastProcessedContent = "";
let lastStrongholdId = null;

// --- YOUR EXACT DBUS LOGIC ---
const callDBus = (method, args) => execSync(`gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.${method} ${args}`).toString();

const closeNotification = (id) => {
  try {
    callDBus("CloseNotification", `${id}`);
  } catch {
    // Notification might already be closed by user
  }
};

const createNotification = (title, text, time) => {
  const raw = callDBus(
    "Notify",
    `"Portal Locator" 0 "" "${title}" "${text}" "[]" "{'urgency': <2>}" 0 | sed -E 's/^\\(([^,]+),.*$/\\1/'`
  );

  const id = raw.trim().split(' ').pop();

  if (time !== undefined) setTimeout(() => closeNotification(id), time);
  return id;
};

// --- SPECIALIZED EVENT FUNCTIONS ---

const pointAdded = (count, ang) => {
  console.log(`\x1b[34m[EYE #${count}] Locked: ${ang.toFixed(2)}°\x1b[0m`);
  exec(`pw-play /usr/share/sounds/freedesktop/stereo/message-new-instant.oga`);
  createNotification(`Eye #${count}`, `Angle: ${ang.toFixed(2)}°`, 5000);
};

const strongholdFound = (ow, nether) => {
  console.log(`\x1b[32m[SUCCESS] ${ow} | ${nether}\x1b[0m`);
  exec(`pw-play /usr/share/sounds/freedesktop/stereo/complete.oga`);
  lastStrongholdId = createNotification("Stronghold Located", `${ow}\n${nether}`, undefined);
};

const pointFailed = (reason) => {
  console.log(`\x1b[31m[ERROR] ${reason}\x1b[0m`);
  exec(`pw-play /usr/share/sounds/freedesktop/stereo/network-connectivity-lost.oga`);
  createNotification("Calculation Failed", reason, 5000);
};

const programStart = () => {
  console.log(`\x1b[36m[START] Speedrun Tool Active\x1b[0m`);
};

// --- MATH UTILITIES ---
const normalizeAngle = (ang) => {
  let a = ang % 360;
  return a > 180 ? a - 360 : (a < -180 ? a + 360 : a);
};

const findIntersection = (p1, p2) => {
  const r1 = (p1.ang * Math.PI) / 180;
  const r2 = (p2.ang * Math.PI) / 180;
  const v1 = { dx: -Math.sin(r1), dz: Math.cos(r1) };
  const v2 = { dx: -Math.sin(r2), dz: Math.cos(r2) };

  const det = v1.dx * (-v2.dz) - (-v2.dx) * v1.dz;
  if (Math.abs(det) < 0.0001) return null;

  const t = ((p2.x - p1.x) * (-v2.dz) - (-v2.dx) * (p2.z - p1.z)) / det;
  return { x: p1.x + t * v1.dx, z: p1.z + t * v1.dz };
};

// --- CORE LOGIC ---
const runCalculations = () => {
  if (points.length < 2) return;

  const p1 = points[points.length - 2];
  const p2 = points[points.length - 1];
  const portal = findIntersection(p1, p2);

  if (!portal) {
    pointFailed("Parallel lines - move and throw again.");
    return;
  }

  const ow = `X: ${portal.x.toFixed(0)} Z: ${portal.z.toFixed(0)}`;
  const nether = `Nether: ${(portal.x / 8).toFixed(0)}, ${(portal.z / 8).toFixed(0)}`;
  
  strongholdFound(ow, nether);
};

const processUpdate = (data) => {
  const match = data.match(REGEX);
  if (!match) return;

  if (lastStrongholdId) {
    closeNotification(lastStrongholdId);
    lastStrongholdId = null;
    points = []; 
    console.log('\x1b[33m[SYSTEM] New run detected. Points reset.\x1b[0m');
  }

  const point = {
    x: parseFloat(match[1]),
    z: parseFloat(match[3]),
    ang: normalizeAngle(parseFloat(match[4]))
  };

  points.push(point);
  if (points.length < 2) pointAdded(points.length, point.ang);
  runCalculations();
};

// --- INITIALIZATION ---
fs.writeFileSync(FILE_PATH, '');
programStart();

// --- POLLING ENGINE ---
setInterval(() => {
  try {
    const content = fs.readFileSync(FILE_PATH, 'utf8').trim();
    if (content && content !== lastProcessedContent) {
      lastProcessedContent = content;
      processUpdate(content);
    }
  } catch {}
}, 500);
