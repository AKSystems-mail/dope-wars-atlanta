// Port of dope_wars_atl/lib/models/game_state.dart + lib/services/game_service.dart.
// Same numbers, same rules, no UI in here — so tool/check.mjs can drive it headless.

import {
  ADS,
  BAG_UPGRADES,
  DIFFICULTY,
  HOODS,
  PRODUCTS,
  WEAPONS,
  type Difficulty,
  type HoodId,
  type Market,
  type Mode,
  type ProductId,
  type Weapon,
  guaranteedProducts,
  hoodById,
  productById,
  resolveMarket,
} from "./data";

export interface WeaponSlot {
  id: string;
  durability: number;
  equipped: boolean;
}

export interface State {
  loc: HoodId;
  cash: number;
  debt: number;
  bank: number;
  day: number;
  maxDays: number;
  hour: number;
  inv: Record<string, number>;
  weapons: WeaponSlot[];
  bag: number;
  over: boolean;
  won: boolean;
  daysPassed: number;
  difficulty: Difficulty;
  sound: boolean;
  music: boolean;
  mode: Mode;
  unlocked: HoodId[];
  heat: number;
  items: Record<string, boolean>;
  informantArmed: boolean;
  informantArrivals: number;
  known: HoodId[];
  market: Market | null;
  bailoutUsed: boolean;
}

export interface Choice {
  label: string;
  color?: string;
  run: () => void;
}

export interface Encounter {
  text: string;
  image?: string;
  choices?: Choice[];
  onDismiss?: () => void;
}

export type Method = "marta" | "ryde" | "drive";

const UNLOCK_ORDER: HoodId[] = ["little_five", "midtown", "west_end", "cobb"];
const STARTING_HOODS: HoodId[] = ["buckhead", "decatur"];
const HEAT_MAX = 100;
const rnd = () => Math.random();

export class Game {
  s: State;
  encounter: Encounter | null = null;
  ad: string | null = null;
  overMessage: string | null = null;
  onChange: () => void = () => {};

  constructor(state?: State) {
    this.s = state ?? newState("normal", 30, "classic");
  }

  static newGame(difficulty: Difficulty, maxDays: number, mode: Mode): Game {
    return new Game(newState(difficulty, maxDays, mode));
  }

  // ---------- derived ----------
  get hood() {
    return hoodById(this.s.loc);
  }
  get invCount() {
    return Object.values(this.s.inv).reduce((a, b) => a + b, 0);
  }
  get space() {
    return this.s.bag - this.invCount;
  }
  get netWorth() {
    return this.s.cash + this.s.bank - this.s.debt;
  }
  get progressive() {
    return this.s.mode === "progressive";
  }
  get heatFactor() {
    return Math.min(2, 1 + this.s.heat / HEAT_MAX);
  }
  get heatLabel() {
    return this.s.heat < 30 ? "Cool" : this.s.heat < 70 ? "Warm" : "Hot";
  }
  get timeLabel() {
    const h = this.s.hour;
    return h < 6 ? "Late Night" : h < 12 ? "Morning" : h < 17 ? "Afternoon" : h < 21 ? "Evening" : "Night";
  }
  get equipped() {
    return this.s.weapons.find((w) => w.equipped) ?? this.s.weapons[0];
  }
  get equippedWeapon(): Weapon {
    return WEAPONS.find((w) => w.id === this.equipped.id) ?? WEAPONS[0];
  }
  isUnlocked(id: string) {
    return !this.progressive || this.s.unlocked.includes(id as HoodId);
  }
  get hasMartaCard() {
    return !!this.s.items.marta_card;
  }
  get nextUnlock(): HoodId | undefined {
    return UNLOCK_ORDER.find((h) => !this.s.unlocked.includes(h));
  }
  get ownsCity() {
    return this.progressive && !this.nextUnlock && this.s.debt <= 0;
  }
  get informantThreshold() {
    return Math.round(DIFFICULTY[this.s.difficulty].cash * 1.5 * (this.s.unlocked.filter((h) => UNLOCK_ORDER.includes(h)).length + 1));
  }
  get rydeSurge() {
    const h = this.s.hour;
    if ((h >= 7 && h <= 9) || (h >= 16 && h <= 19)) return 1.5 + (h % 2 === 0 ? 0.3 : 0);
    if (h >= 23 || h <= 4) return 1.3;
    return 1;
  }
  canTravel(id: string, method: Method) {
    if (!this.isUnlocked(id)) return false;
    if (method === "marta" && this.progressive && !this.hasMartaCard) return false;
    const list = method === "marta" ? this.hood.marta : this.hood.highway;
    return list.includes(id as HoodId);
  }
  costOf(method: Method) {
    if (method === "marta") return 5;
    if (method === "drive") return 20;
    return Math.round((25 + Math.floor(rnd() * 36)) * this.rydeSurge);
  }

  // ---------- market ----------
  ensureMarket(): Market {
    if (this.s.market && this.s.market.hoodId === this.s.loc) {
      this.learn(this.s.loc);
      return this.s.market;
    }
    const visit = (this.s.market?.visit ?? 0) + 1;
    const m = resolveMarket(this.hood, visit);
    this.s.market = m;
    this.learn(this.s.loc);
    return m;
  }
  get market() {
    return this.ensureMarket();
  }
  get shelf() {
    return this.shelfIds().map(productById);
  }
  private shelfIds(): ProductId[] {
    return this.market.shelf;
  }
  private learn(id: HoodId) {
    if (!this.s.known.includes(id)) this.s.known.push(id);
  }

  // ---------- travel ----------
  travel(id: HoodId, method: Method): boolean {
    if (!this.canTravel(id, method)) return false;
    const cost = this.costOf(method);
    if (this.s.cash < cost) return false;

    this.s.cash -= cost;
    const from = this.s.loc;
    this.s.loc = id;
    const dayBefore = this.s.day;
    this.s.hour = (this.s.hour + (method === "drive" ? 1 : 2)) % 24;
    if (this.s.day === dayBefore) this.advanceDay();
    this.interest();

    this.encounter = null;
    this.ad = null;
    this.onArrival();

    let hit = false;
    if (method === "marta") hit = this.martaEncounter();
    else if (method === "ryde") hit = this.rydeEncounter();
    else hit = this.driveEncounter();

    if (!hit) hit = this.locationEvents(method, from);
    if (!hit && id === "midtown") hit = this.waterBoys();
    if (!hit && id === "west_end") hit = this.yns();

    if (!hit) this.maybeInformant();
    this.checkOver();
    if (!this.encounter && !this.overMessage) this.ad = ADS[Math.floor(rnd() * ADS.length)];
    this.sound(method);
    this.onChange();
    return true;
  }

  private sound(method: Method) {
    if (!this.s.sound) return;
    this.sfx(method === "marta" ? "marta_chime" : method === "ryde" ? "car_horn" : "car_horn");
  }
  /** Replaced by main.ts; no-ops headless. */
  sfx: (name: string) => void = () => {};

  private onArrival() {
    this.ensureMarket();
    this.raiseHeat(this.s.won ? 3 : 1);
  }

  private roll(basePercent: number) {
    const scaled = Math.min(100, Math.max(1, Math.round(basePercent * this.heatFactor)));
    return rnd() * 100 < scaled;
  }

  private advanceDay() {
    this.s.day++;
    this.s.daysPassed++;
  }

  private interest() {
    if (this.s.debt > 0) this.s.debt += Math.round(this.s.debt * 0.02);
    if (this.s.bank > 0) this.s.bank += Math.round(this.s.bank * 0.01);
  }

  private raiseHeat(n: number) {
    if (n <= 0) return;
    this.s.heat = Math.min(HEAT_MAX, this.s.heat + n);
  }
  private coolHeat(n: number) {
    if (n <= 0 || this.s.won) return false;
    const before = this.s.heat;
    this.s.heat = Math.max(0, this.s.heat - n);
    return this.s.heat < before;
  }

  layLow() {
    this.coolHeat(10);
    const dayBefore = this.s.day;
    this.s.hour = (this.s.hour + 2) % 24;
    if (this.s.day === dayBefore) this.advanceDay();
    this.interest();
    this.checkOver();
    this.onChange();
  }

  // ---------- encounters ----------
  private block(text: string, onDismiss?: () => void, image?: string) {
    this.encounter = { text, onDismiss, image };
    this.sfx("encounter");
  }
  private withChoices(text: string, choices: Choice[], image?: string) {
    this.encounter = { text, choices, image };
    this.sfx("encounter");
  }
  dismissEncounter() {
    const e = this.encounter;
    this.encounter = null;
    e?.onDismiss?.();
    this.checkOver();
    this.onChange();
  }
  clearEncounter() {
    this.encounter = null;
    this.checkOver();
    this.onChange();
  }

  private martaEncounter() {
    if (!this.roll(3)) return false;
    this.withChoices('👮 MARTA POLICE\n"Hold it right there!"\n\nWhat do you do?', [
      { label: "RUN", color: "#e53935", run: () => this.runFromPolice() },
      { label: "FIGHT", color: "#ff00f7", run: () => this.fightPolice() },
    ]);
    return true;
  }

  private rydeEncounter() {
    if (!this.roll(3)) return false;
    this.withChoices('👮‍♂️ RYDE COP\n"License and registration."\n\nHe smells something...', [
      { label: "BRIBE $200", color: "#fdd835", run: () => this.bribeCop() },
      { label: "RUN", color: "#e53935", run: () => this.runFromPolice() },
    ]);
    return true;
  }

  private driveEncounter() {
    if (!this.roll(6)) return false;
    if (rnd() * 100 < 75) {
      this.arrested("🚔 GSP CHASE\nBlue lights flash. You pull over.\nYou're arrested for trafficking.\n\nLose 75% of your inventory!\nWeapon confiscated!", () => {
        this.loseInvPercent(0.75);
        this.confiscateWeapon();
      });
    } else {
      this.block("🚗💨 GSP CHASE\nYou outran the state patrol!\n\nYour heart is pounding but you're free.");
    }
    return true;
  }

  private waterBoys() {
    if (!this.roll(8)) return false;
    if (this.invCount <= 0) return false;
    const lost = Math.max(1, Math.round(this.invCount * 0.3));
    this.block(`💧 WATER BOYS\n"Say, you got any water?"\n\nThey swarm your ride and jack ${lost} units of product!\n\n"Thanks, player."`, () => {
      this.loseInvPercent(0.3);
    });
    return true;
  }

  private yns() {
    if (!this.roll(10)) return false;
    if (this.equippedWeapon.id !== "fists") {
      this.block(`🫡 YNs\n"Yo, what hood you claim?"\n\nThey eye your ${this.equippedWeapon.emoji} and nod.\n"Cool, cool. Stay safe out here."\n\nThey let you pass.`);
    } else {
      const loss = 100 + Math.floor(rnd() * 201);
      const actual = Math.min(loss, this.s.cash);
      this.block(`🫡 YNs\n"Yo, what hood you claim?"\n\nYou ain't strapped. They take $${actual}.\n"Next time come correct."`, () => {
        this.s.cash = Math.max(0, this.s.cash - actual);
      });
    }
    return true;
  }

  private runFromPolice() {
    const chance = this.equippedWeapon.killChance * 0.6;
    if (rnd() <= chance) {
      this.block("🏃‍♂️ You bolted!\n\nYou disappeared into the Atlanta night.\n\nClose one.");
    } else {
      this.useDurability();
      this.arrested("🚔 You got tackled!\n\nYou're cuffed and arrested.", () => this.loseInvPercent(0.5));
    }
  }

  private fightPolice() {
    const chance = this.equippedWeapon.killChance;
    const broke = this.useDurability();
    if (!this.equippedWeapon.id.startsWith("fists")) this.sfx("weapon_fire");
    if (rnd() <= chance) {
      this.block(
        `💥 You won the fight!\n\n${this.equippedWeapon.name} did the job.\nOfficer down. You slip away.\n\n${broke ? "Your weapon broke in the struggle!" : ""}`,
      );
    } else {
      this.arrested("😵 You got clobbered!\n\nWoke up in cuffs.\nLose 50% of inventory.", () => this.loseInvPercent(0.5));
    }
  }

  private bribeCop() {
    if (this.s.cash < 200) {
      this.arrested("😬 You don't have $200!\n\nCop gets out.\nYou're arrested.");
      return;
    }
    this.s.cash -= 200;
    if (rnd() * 100 < 70) {
      this.block('💵 "Have a safe night."\n\nCop pockets the bribe and walks away.\n-$200');
    } else {
      this.arrested('🙅 "Step out of the vehicle."\n\nHe took your $200 AND arrested you.');
    }
  }

  private arrested(text: string, consequence?: () => void) {
    consequence?.();
    const fine = Math.min(5000, Math.max(100, Math.round(this.s.cash * 0.5)));
    this.withChoices(text, [
      {
        label: `PAY $${fine}`,
        color: "#fdd835",
        run: () => {
          this.s.cash = Math.max(0, this.s.cash - fine);
          this.clearEncounter();
        },
      },
      {
        label: "CALL COUNCILMAN",
        color: "#ff00f7",
        run: () => {
          this.s.debt += 500;
          this.clearEncounter();
        },
      },
    ]);
  }

  private maybeInformant() {
    if (!this.progressive) return;
    const next = this.nextUnlock;
    if (!next) return;
    if (!this.s.informantArmed) {
      if (this.s.cash >= this.informantThreshold) this.s.informantArmed = true;
      return;
    }
    if (this.s.loc === "cobb") return;
    this.s.informantArrivals++;
    const due = this.s.informantArrivals >= 3;
    if (!due && rnd() * 100 >= 45) return;

    const localCheap = this.hood.cheap;
    const options = PRODUCTS.filter((p) => p.id !== localCheap);
    const held = options.filter((p) => (this.s.inv[p.id] ?? 0) > 0);
    const pool = held.length ? held : options;
    const fee = pool[Math.floor(rnd() * pool.length)];
    const qty = 1 + Math.floor(rnd() * 5);
    const canPay = (this.s.inv[fee.id] ?? 0) >= qty;

    this.withChoices(
      `A figure steps out of a doorway, hands in pockets.\n\n"${hoodById(next).name}. I can get you in." He looks at your bag.\n"${qty} ${fee.name}. That is the toll."`,
      [
        ...(canPay
          ? [
              {
                label: `PAY — ${qty}x ${fee.name}`,
                color: "#00ff9d",
                run: () => {
                  this.removeInv(fee.id, qty);
                  this.s.unlocked.push(next);
                  this.learn(next);
                  this.s.informantArmed = false;
                  this.s.informantArrivals = 0;
                  this.clearEncounter();
                },
              },
            ]
          : []),
        {
          label: canPay ? "NOT NOW" : "NOT CARRYING IT",
          color: "#9ca3af",
          run: () => {
            this.s.informantArrivals = 0;
            this.clearEncounter();
          },
        },
      ],
      "assets/images/informant_encounter.png",
    );
  }

  private locationEvents(_method: Method, _from: HoodId) {
    return false; // no location-specific travel events in the Flutter build either
  }

  // ---------- shop ----------
  buy(id: string, qty: number): boolean {
    const m = this.market;
    if (!m.shelf.includes(id as ProductId)) return false;
    const price = m.buy[id] ?? 0;
    if (price <= 0 || qty <= 0) return false;
    if (this.s.cash < price * qty) return false;
    if (this.space < qty) return false;
    this.s.cash -= price * qty;
    this.s.inv[id] = (this.s.inv[id] ?? 0) + qty;
    this.sfx("cash");
    this.checkOver();
    this.onChange();
    return true;
  }

  sell(id: string, qty: number): boolean {
    const held = this.s.inv[id] ?? 0;
    if (held <= 0) return false;
    const m = this.market;
    if (!m.shelf.includes(id as ProductId)) return false;
    const price = m.sell[id] ?? 0;
    if (price <= 0) return false;
    const n = Math.min(qty, held);
    this.s.cash += price * n;
    this.removeInv(id, n);
    this.raiseHeat(1 + Math.floor(n / 25));
    if (this.progressive && !this.hasMartaCard) {
      this.s.items.marta_card = true;
      this.block("💳 MARTA CARD\n\nA Breeze card, still warm, on the pavement where your buyer stood.\n\nThe trains are open to you now — five dollars a ride.");
    }
    this.sfx("cash");
    this.checkOver();
    this.onChange();
    return true;
  }

  dump(id: string, qty: number) {
    if (qty < 5 || (this.s.inv[id] ?? 0) < qty || this.s.won) return 0;
    this.removeInv(id, qty);
    const before = this.s.heat;
    this.coolHeat(Math.floor(qty / 25));
    this.onChange();
    return before - this.s.heat;
  }

  private removeInv(id: string, qty: number) {
    const held = this.s.inv[id] ?? 0;
    if (held <= qty) delete this.s.inv[id];
    else this.s.inv[id] = held - qty;
  }
  private loseInvPercent(pct: number) {
    const total = this.invCount;
    if (!total) return;
    let toLose = Math.min(total, Math.max(1, Math.round(total * pct)));
    for (const key of Object.keys(this.s.inv).sort(() => rnd() - 0.5)) {
      if (toLose <= 0) break;
      const q = this.s.inv[key];
      if (q <= toLose) {
        delete this.s.inv[key];
        toLose -= q;
      } else {
        this.s.inv[key] = q - toLose;
        toLose = 0;
      }
    }
  }

  // ---------- weapons ----------
  buyWeapon(w: Weapon) {
    if (this.s.cash < w.price) return false;
    this.s.cash -= w.price;

    const owned = this.s.weapons.find((s) => s.id === w.id && !(w.maxDurability <= 5 && s.durability <= 0));
    if (owned) {
      owned.durability = w.maxDurability;
      this.equipById(w.id);
      this.sfx("cash");
      this.onChange();
      return true;
    }
    if (this.s.weapons.length < 3) {
      this.s.weapons.push({ id: w.id, durability: w.maxDurability, equipped: true });
      this.equipById(w.id);
      this.sfx("cash");
      this.onChange();
      return true;
    }
    const replaceable = this.s.weapons
      .filter((s) => s.id !== "fists" && !s.equipped)
      .sort((a, b) => (WEAPONS.find((x) => x.id === a.id)?.price ?? 0) - (WEAPONS.find((x) => x.id === b.id)?.price ?? 0))[0];
    if (replaceable) {
      this.s.weapons.splice(this.s.weapons.indexOf(replaceable), 1);
      this.s.weapons.push({ id: w.id, durability: w.maxDurability, equipped: true });
      this.equipById(w.id);
      this.sfx("cash");
      this.onChange();
      return true;
    }
    this.s.cash += w.price;
    return false;
  }

  equipById(id: string) {
    for (const s of this.s.weapons) s.equipped = s.id === id;
    this.onChange();
  }

  private useDurability(): boolean {
    const slot = this.s.weapons.find((s) => s.equipped);
    if (!slot) return false;
    slot.durability--;
    const w = WEAPONS.find((x) => x.id === slot.id)!;
    if (w.maxDurability <= 5 && slot.durability <= 0) {
      slot.equipped = false;
      this.autoSwitch();
      return true;
    }
    return false;
  }

  private confiscateWeapon() {
    const i = this.s.weapons.findIndex((s) => s.equipped && s.id !== "fists");
    if (i >= 0) this.s.weapons.splice(i, 1);
    this.autoSwitch();
  }

  private autoSwitch() {
    if (!this.s.weapons.length) {
      this.s.weapons.push({ id: "fists", durability: 9999, equipped: true });
      return;
    }
    const good = this.s.weapons.find((s) => s.id !== "fists" && s.durability > 0);
    if (good) {
      good.equipped = true;
      return;
    }
    const fists = this.s.weapons.find((s) => s.id === "fists");
    if (fists) {
      fists.equipped = true;
      fists.durability = 9999;
    } else this.s.weapons.push({ id: "fists", durability: 9999, equipped: true });
  }

  // ---------- bank / councilman / bookbag ----------
  deposit(n: number) {
    if (n <= 0 || this.s.cash < n) return false;
    this.s.cash -= n;
    this.s.bank += n;
    this.coolHeat(2);
    this.onChange();
    return true;
  }
  withdraw(n: number) {
    if (n <= 0 || this.s.bank < n) return false;
    this.s.bank -= n;
    this.s.cash += n;
    this.onChange();
    return true;
  }
  payDebt(n: number) {
    const payment = Math.min(n, this.s.debt);
    if (payment <= 0 || this.s.cash < payment) return false;
    this.s.cash -= payment;
    this.s.debt -= payment;
    this.coolHeat(Math.floor(payment / 1000));
    this.checkOver();
    this.onChange();
    return true;
  }
  borrow(n: number) {
    if (n <= 0) return false;
    this.s.debt += n;
    this.s.cash += n;
    this.onChange();
    return true;
  }
  upgradeBag(capacity: number, cost: number) {
    if (this.s.cash < cost || capacity <= this.s.bag) return false;
    this.s.cash -= cost;
    this.s.bag = capacity;
    this.sfx("cash");
    this.onChange();
    return true;
  }
  setSetting(patch: Partial<Pick<State, "sound" | "music">>) {
    Object.assign(this.s, patch);
    this.onChange();
  }

  // ---------- end states ----------
  checkOver(): string | null {
    if (this.s.over) return this.overMessage;
    if (this.progressive && !this.s.won && this.ownsCity) {
      this.s.won = true;
      this.s.over = true;
      this.overMessage = "🏆 YOU OWN THE CITY\nEvery hood is open and the Councilman is square.\nNothing left to prove here — but the heat is still rising.";
      return this.overMessage;
    }
    if (this.s.cash <= 0 && this.invCount <= 0) {
      this.s.over = true;
      this.overMessage = this.progressive
        ? "💀 GAME OVER\nEmpty pockets and an empty bag.\nOut here that is the end of the road."
        : "💀 GAME OVER\nYou're broke with nothing to sell.\nThe Councilman might help... for a price.";
      return this.overMessage;
    }
    if (this.s.day > this.s.maxDays) {
      this.s.over = true;
      if (this.progressive) {
        this.overMessage = "💀 TIME UP\nThe city is not yours yet.\nBut you are still standing.";
      } else if (this.s.debt <= 0) {
        this.s.won = true;
        this.overMessage = `🏆 YOU WIN!\nSurvived ${this.s.daysPassed} days with the debt cleared.\nNet worth: $${this.netWorth}`;
      } else {
        this.overMessage = "💀 GAME OVER\nYou ran out of time with debt remaining.";
      }
      return this.overMessage;
    }
    return null;
  }

  bailout() {
    this.s.debt += 2000;
    this.s.cash = 500;
    this.s.over = false;
    this.overMessage = null;
    this.s.bailoutUsed = true;
    this.onChange();
  }

  dismissOver() {
    this.overMessage = null;
    // Winning ends a Classic run, but Progressive's win puts you back in play.
    if (this.s.over && !(this.progressive && this.s.won)) this.s.over = true;
    this.onChange();
  }

  dismissAd() {
    this.ad = null;
    this.onChange();
  }

  // ---------- save ----------
  toJSON(): State {
    return { ...this.s, market: this.s.market };
  }
  static fromJSON(raw: unknown): Game | null {
    if (!raw || typeof raw !== "object") return null;
    const d = raw as Partial<State>;
    if (!HOODS.some((h) => h.id === d.loc)) return null;
    const base = newState(d.difficulty ?? "normal", d.maxDays ?? 30, d.mode ?? "classic");
    return new Game({
      ...base,
      ...d,
      loc: d.loc as HoodId,
      inv: d.inv ?? {},
      weapons: d.weapons?.length ? d.weapons : base.weapons,
      unlocked: (d.unlocked ?? []) as HoodId[],
      known: (d.known ?? []) as HoodId[],
      items: d.items ?? {},
      market: (d.market ?? null) as Market | null,
      over: false,
      bailoutUsed: d.bailoutUsed ?? false,
    });
  }
}

export function newState(difficulty: Difficulty, maxDays: number, mode: Mode): State {
  const d = DIFFICULTY[difficulty];
  return {
    loc: "buckhead",
    cash: d.cash,
    debt: d.debt,
    bank: 0,
    day: 1,
    maxDays,
    hour: 8,
    inv: {},
    weapons: [{ id: "fists", durability: 9999, equipped: true }],
    bag: 100,
    over: false,
    won: false,
    daysPassed: 0,
    difficulty,
    sound: true,
    music: true,
    mode,
    unlocked: mode === "progressive" ? [...STARTING_HOODS] : [],
    heat: 0,
    items: {},
    informantArmed: false,
    informantArrivals: 0,
    known: [],
    market: null,
    bailoutUsed: false,
  };
}

export { BAG_UPGRADES, HOODS, PRODUCTS, WEAPONS, guaranteedProducts, hoodById, productById };
