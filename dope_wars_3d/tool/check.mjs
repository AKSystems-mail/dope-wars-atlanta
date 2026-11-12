// Headless rules check. Builds src/game.ts with esbuild (already here via vite),
// then drives the real engine — no browser, no mocks beyond seeded randomness.
import { build } from "esbuild";
import assert from "node:assert/strict";

const out = await build({
  stdin: { contents: 'export * from "./game"; export * from "./data";', resolveDir: "src", loader: "ts" },
  bundle: true,
  format: "esm",
  platform: "node",
  write: false,
});
const code = out.outputFiles[0].text;
const { Game, DIFFICULTY, WEAPONS } = await import("data:text/javascript;base64," + Buffer.from(code).toString("base64"));

const ok = [];
const t = (name, fn) => {
  fn();
  ok.push(name);
};

// deterministic rolls: 1 = never fires, 0 = always fires
const seed = (v) => {
  const orig = Math.random;
  Math.random = () => v;
  return () => (Math.random = orig);
};

t("new game numbers", () => {
  const g = Game.newGame("normal", 30, "classic");
  assert.equal(g.s.cash, DIFFICULTY.normal.cash);
  assert.equal(g.s.debt, DIFFICULTY.normal.debt);
  assert.equal(g.s.bag, 100);
  assert.equal(g.s.day, 1);
  assert.ok(g.market.shelf.length >= 3, "a shelf never thins out below guaranteed+2");
  for (const h of ["decatur", "buckhead", "midtown", "west_end", "little_five", "cobb"]) {
    g.s.loc = h;
    g.s.market = null;
    assert.ok(g.market.shelf.length >= 3 && g.market.shelf.length <= 5, `shelf size in ${h}`);
    for (const id of g.market.shelf) assert.ok(g.market.sell[id] < g.market.buy[id], `${h}/${id} spread`);
  }
  assert.equal(g.s.weapons.length, 1, "starts with fists");
});

t("market prices respect the ring", () => {
  const g = Game.newGame("normal", 30, "classic");
  for (let i = 0; i < 40; i++) {
    const to = ["decatur", "buckhead", "midtown", "west_end", "little_five", "cobb"]
      .filter((h) => g.isUnlocked(h))
      .at(i % 4);
    if (to && to !== g.s.loc) g.travel(to, "marta");
    for (const id of g.market.shelf) {
      const p = g.market.buy[id];
      assert.ok(Number.isFinite(p) && p > 0, `bad price for ${id}`);
      assert.ok(g.market.sell[id] < p, "sell must undercut buy");
    }
  }
});

t("buy then sell loses money but moves product", () => {
  const g = Game.newGame("normal", 30, "classic");
  const id = g.market.shelf[0];
  const before = g.s.cash;
  assert.equal(g.buy(id, 5), true);
  assert.equal(g.s.inv[id], 5);
  assert.equal(g.s.cash, before - g.market.buy[id] * 5);
  const cashAfterBuy = g.s.cash;
  g.sell(id, 5);
  assert.equal(g.s.inv[id] ?? 0, 0);
  assert.ok(g.s.cash > cashAfterBuy, "selling returns money");
});

t("bag capacity is a hard wall", () => {
  const g = Game.newGame("normal", 30, "classic");
  const id = g.market.shelf[0];
  g.s.cash = 1e9;
  const bought = g.buy(id, 101);
  assert.equal(bought, false, "one unit over capacity is refused");
  assert.ok(g.invCount <= g.s.bag);
  assert.equal(g.buy(id, g.space), true);
  assert.equal(g.invCount, g.s.bag);
  assert.equal(g.buy(id, 1), false);
});

t("travel costs a day and the fare", () => {
  const g = Game.newGame("normal", 30, "classic");
  const cash = g.s.cash;
  const day = g.s.day;
  assert.equal(g.travel("decatur", "marta"), true);
  assert.equal(g.s.loc, "decatur");
  assert.equal(g.s.day, day + 1);
  assert.equal(g.s.cash, cash - 5);
  assert.equal(g.isUnlocked("cobb"), true, "classic opens the whole city");
  const p = Game.newGame("normal", 30, "progressive");
  assert.equal(p.isUnlocked("west_end"), false, "progressive starts with two hoods");
  assert.equal(p.travel("west_end", "marta"), false, "locked hood cannot be reached");
});

t("bank deposits, withdraws and pays interest", () => {
  const g = Game.newGame("normal", 30, "classic");
  g.travel("midtown", "marta");
  const cashBefore = g.s.cash;
  g.deposit(1000);
  assert.equal(g.s.bank, 1000);
  assert.equal(g.s.cash, cashBefore - 1000);
  g.travel("decatur", "marta");
  assert.ok(g.s.bank >= 1010, "1% interest lands overnight");
  g.travel("midtown", "marta");
  const bank = g.s.bank;
  g.withdraw(500);
  assert.equal(g.s.bank, bank - 500);
});

t("councilman: borrow, pay, and 2% a day", () => {
  const g = Game.newGame("normal", 30, "classic");
  const debt = g.s.debt;
  g.borrow(1000);
  assert.equal(g.s.debt, debt + 1000);
  assert.equal(g.s.cash, DIFFICULTY.normal.cash + 1000);
  g.payDebt(2000);
  assert.equal(g.s.debt, debt - 1000);
  g.travel("decatur", "marta");
  assert.ok(g.s.debt > debt - 1000, "interest accrues");
});

t("weapons: buy, equip, spend durability", () => {
  const g = Game.newGame("normal", 30, "classic");
  g.s.cash = 50000;
  g.travel("west_end", "marta");
  const blicky = WEAPONS.find((w) => w.id === "blicky");
  g.buyWeapon(blicky);
  assert.ok(g.s.weapons.some((w) => w.id === "blicky"), "the gun is in the bag");
  g.equipById("fists");
  g.equipById("blicky");
  assert.equal(g.equippedWeapon.id, "blicky");
  const uses = g.s.weapons.find((w) => w.id === "blicky").durability;
  g.useDurability();
  assert.equal(g.s.weapons.find((w) => w.id === "blicky").durability, uses - 1, "a fight spends one use");
  for (let i = 0; i < uses; i++) g.useDurability();
  const spent = g.s.weapons.find((w) => w.id === "blicky");
  assert.equal(spent.durability, 0, "an empty gun stops counting down");
  assert.equal(spent.equipped, false, "and comes out of the hand");
  assert.equal(g.equippedWeapon.id, "fists", "the bag falls back to fists");
});

t("dump cools heat and shrinks the bag", () => {
  const g = Game.newGame("normal", 30, "progressive");
  const id = g.market.shelf[0];
  g.s.cash = 1e6;
  g.buy(id, 60);
  g.s.heat = 60;
  const cooled = g.dump(id, 25);
  assert.equal(g.s.inv[id], 35);
  assert.ok(cooled > 0, "dropping 25 units is worth heat");
  assert.ok(g.s.heat < 60, "dumping drops heat");
});

t("save round-trips", () => {
  const g = Game.newGame("hard", 60, "progressive");
  g.buy(g.market.shelf[0], 3);
  g.deposit(250);
  const wire = JSON.parse(JSON.stringify(g.toJSON()));
  const back = Game.fromJSON(wire);
  assert.deepEqual(JSON.parse(JSON.stringify(back.toJSON())), wire, "save survives a trip through JSON");
  assert.equal(back.s.maxDays, 60);
});

t("200 random days keep the books sane", () => {
  const g = Game.newGame("normal", 90, "classic");
  g.s.cash = 20000;
  for (let i = 0; i < 200 && !g.s.over; i++) {
    const hoods = ["decatur", "buckhead", "midtown", "west_end", "little_five", "cobb"].filter((h) => g.isUnlocked(h));
    const to = hoods[Math.floor(Math.random() * hoods.length)];
    if (to !== g.s.loc) g.travel(to, Math.random() < 0.5 ? "marta" : "ryde");
    if (g.encounter) {
      const c = g.encounter.choices;
      if (c) c[Math.floor(Math.random() * c.length)].run();
      g.dismissEncounter();
    }
    if (g.s.cash > 0) {
      const id = g.market.shelf[Math.floor(Math.random() * g.market.shelf.length)];
      g.buy(id, 1 + Math.floor(Math.random() * 3));
      g.sell(id, g.s.inv[id] ?? 0);
    }
    assert.ok(Number.isFinite(g.s.cash) && g.s.cash >= 0, "cash stays a number and non-negative");
    assert.ok(g.s.debt >= 0 && Number.isFinite(g.s.debt));
    assert.ok(g.invCount >= 0 && g.invCount <= g.s.bag, "bag stays within capacity");
    assert.ok(g.s.day >= 1 && g.s.day <= g.s.maxDays + 1, "day stays in range");
  }
  assert.ok(g.s.day > 5, "the loop actually advanced days");
});

t("time up with debt is a loss", () => {
  const g = Game.newGame("normal", 1, "classic");
  g.travel("decatur", "marta");
  assert.ok(g.overMessage && /TIME UP|GAME OVER/.test(g.overMessage), "reaching the last day ends the run");
});

console.log(`
${ok.length} checks passed:`);
for (const n of ok) console.log("  ✓ " + n);
