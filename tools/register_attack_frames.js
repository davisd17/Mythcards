// Registers a delivered attack sequence in game/assets/figures/wardrobe.json
// (LLD-figure-animation.md 8; docs/art-specs/attack-windup-spec.html).
//
// Usage: node tools/register_attack_frames.js <character-id> [outfit-id] [--holds 100,100,130,60,90,120]
//
// Frames live in game/assets/figures/<character-id>/:
//   default outfit:  attack-1-ready.png ... attack-6-recover.png
//   other outfits:   <outfit-id>-attack-1-ready.png ... (the poses are the character's
//                    locked pose reference, re-dressed per outfit)
// Pose 4 (Fire) is the impact. The outfit must already be listed in wardrobe.json.
// Then run tools/run_game_tests.ps1: test_attack_art_contract.gd checks the canvas, the
// foot line, and the margins of every registered frame.

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const WARDROBE = path.join(ROOT, "game/assets/figures/wardrobe.json");
const POSES = ["ready", "raise", "brace", "fire", "recoil", "recover"];
const DEFAULT_HOLDS = [100, 100, 130, 60, 90, 120];
const IMPACT = 3;

function fail(message) {
	console.error("register_attack_frames: " + message);
	process.exit(1);
}

const args = process.argv.slice(2);
const holdsAt = args.indexOf("--holds");
let holds = DEFAULT_HOLDS;
if (holdsAt >= 0) {
	holds = (args[holdsAt + 1] || "").split(",").map(Number);
	args.splice(holdsAt, 2);
	if (holds.length !== POSES.length || holds.some((h) => !(h > 0))) fail("--holds needs 6 positive numbers");
}
const [characterId, outfitId = "default"] = args;
if (!characterId) fail("usage: node tools/register_attack_frames.js <character-id> [outfit-id] [--holds a,b,c,d,e,f]");

const folder = path.join(ROOT, "game/assets/figures", characterId);
if (!fs.existsSync(folder)) fail(`no figure folder ${path.relative(ROOT, folder)}`);
const prefix = outfitId === "default" ? "attack-" : `${outfitId}-attack-`;
const frames = POSES.map((pose, i) => {
	const file = `${prefix}${i + 1}-${pose}.png`;
	if (!fs.existsSync(path.join(folder, file))) fail(`missing ${characterId}/${file}`);
	const frame = { texture: `res://assets/figures/${characterId}/${file}`, ms: holds[i] };
	if (i === IMPACT) frame.impact = true;
	return frame;
});

const wardrobe = JSON.parse(fs.readFileSync(WARDROBE, "utf8"));
const outfits = wardrobe[characterId];
if (!Array.isArray(outfits)) fail(`${characterId} is not in wardrobe.json`);
const entry = outfits.find((o) => o.id === outfitId);
if (!entry) fail(`${characterId} has no outfit "${outfitId}" in wardrobe.json; add the outfit first`);
entry.attack = frames;

// Same layout as the hand-written file: one character per line, attack frames one per line.
const lines = Object.entries(wardrobe).map(([id, list]) => {
	const items = list.map((o) => {
		const { attack, ...rest } = o;
		const head = JSON.stringify(rest);
		if (!attack) return head;
		return head.slice(0, -1) + ',\n    "attack":[' + attack.map((f) => JSON.stringify(f)).join(",\n      ") + "]}";
	});
	return `  ${JSON.stringify(id)}: [${items.join(", ")}]`;
});
fs.writeFileSync(WARDROBE, "{\n" + lines.join(",\n") + "\n}\n");
console.log(`Registered ${characterId}/${outfitId}: ${frames.length} poses, ${holds.reduce((a, b) => a + b, 0)} ms, impact on pose 4 (Fire).`);
console.log("Next: tools/run_game_tests.ps1 (test_attack_art_contract checks the art).");
