// Ported from dope_wars_atl/lib/models/{product,weapon,location,market}.dart
// Tuning numbers are copied, not re-invented. See ../../SPEC.md + docs/PRICING_SPEC.md.

export type ProductId = "blunts" | "oxy" | "shrooms" | "powda" | "acid";
export type HoodId = "west_end" | "midtown" | "little_five" | "buckhead" | "decatur" | "cobb";
export type Difficulty = "easy" | "normal" | "hard";
export type Mode = "classic" | "progressive";

export interface Product {
  id: ProductId;
  name: string;
  base: number;
  emoji: string;
}

export const PRODUCTS: Product[] = [
  { id: "blunts", name: "Blunts", base: 60, emoji: "🌿" },
  { id: "oxy", name: "Oxy", base: 20, emoji: "💊" },
  { id: "shrooms", name: "Shrooms", base: 150, emoji: "🍄" },
  { id: "powda", name: "Powda", base: 120, emoji: "❄️" },
  { id: "acid", name: "Acid", base: 55, emoji: "💧" },
];

export const productById = (id: string) => PRODUCTS.find((p) => p.id === id)!;

export interface Weapon {
  id: string;
  name: string;
  killChance: number;
  maxDurability: number;
  price: number;
  emoji: string;
}

export const WEAPONS: Weapon[] = [
  { id: "fists", name: "Fists", killChance: 0.45, maxDurability: 9999, price: 0, emoji: "✊" },
  { id: "blicky", name: "Blicky", killChance: 0.52, maxDurability: 5, price: 300, emoji: "🔫" },
  { id: "strap", name: "Strap", killChance: 0.63, maxDurability: 5, price: 550, emoji: "🔫" },
  { id: "draco", name: "Draco", killChance: 0.77, maxDurability: 5, price: 3000, emoji: "🔫" },
];

export interface Location {
  id: HoodId;
  name: string;
  description: string;
  accent: string;
  marta: HoodId[];
  highway: HoodId[];
  cheap?: ProductId;
  premium: ProductId[];
  guaranteeWholeRing?: boolean;
  bank?: boolean;
  weapons?: boolean;
  councilman?: boolean;
  bookbag?: boolean;
  /** Source pixel coords on map_background_v3.jpg (606x1280). */
  at: [number, number];
}

export const HOODS: Location[] = [
  {
    id: "west_end",
    name: "West End",
    description: "Weapons spot. Keep your head up.",
    accent: "#e53935",
    marta: ["midtown", "decatur"],
    highway: ["midtown", "decatur"],
    cheap: "powda",
    premium: ["oxy"],
    weapons: true,
    at: [255, 690],
  },
  {
    id: "midtown",
    name: "Midtown",
    description: "The Bank. Money moves here.",
    accent: "#1e88e5",
    marta: ["little_five", "west_end", "buckhead", "decatur"],
    highway: ["buckhead", "decatur", "west_end"],
    cheap: "oxy",
    premium: ["shrooms"],
    bank: true,
    at: [312, 618],
  },
  {
    id: "little_five",
    name: "Little Five Points",
    description: "Eclectic. Underground. Bookbag upgrades here.",
    accent: "#ab47bc",
    marta: ["midtown", "decatur"],
    highway: ["decatur"],
    cheap: "shrooms",
    premium: ["acid"],
    bookbag: true,
    at: [395, 627],
  },
  {
    id: "buckhead",
    name: "Buckhead",
    description: "The Councilman holds court here. Money talks.",
    accent: "#fdd835",
    marta: ["midtown", "decatur"],
    highway: ["midtown", "decatur", "cobb"],
    cheap: "blunts",
    premium: ["powda"],
    guaranteeWholeRing: true,
    councilman: true,
    at: [330, 500],
  },
  {
    id: "decatur",
    name: "Decatur",
    description: "College town. Solid middle market.",
    accent: "#fb8c00",
    marta: ["little_five", "west_end", "midtown", "buckhead"],
    highway: ["little_five", "midtown", "buckhead", "cobb", "west_end"],
    cheap: "acid",
    premium: ["blunts"],
    guaranteeWholeRing: true,
    at: [478, 636],
  },
  {
    id: "cobb",
    name: "Cobb County",
    description: "Out past the perimeter. Different rules out here.",
    accent: "#78909c",
    marta: [],
    highway: ["buckhead", "decatur"],
    premium: ["oxy", "shrooms"],
    at: [148, 300],
  },
];

export const reputationLine = (h: Location) =>
  [
    h.cheap ? `cheap ${productById(h.cheap).name}` : "",
    h.premium.length ? `pays for ${h.premium.map((p) => productById(p).name).join(" and ")}` : "",
  ]
    .filter(Boolean)
    .join(" · ") || "middle market, nothing special";

export const hoodById = (id: string): Location => HOODS.find((h) => h.id === id) ?? HOODS[3];

// ---- Pricing (lib/models/market.dart) ----
export const P = {
  cheapMult: 0.7,
  premiumMult: 1.5,
  spikeMult: 1.5,
  floodMult: 0.3,
  buySide: 1.0625,
  sellSide: 0.9375,
  jitterLow: 0.85,
  jitterHigh: 1.15,
  spikeChance: 15,
  floodChance: 10,
  extrasMin: 2,
  extrasMax: 3,
};

export const valueMultFor = (hood: Location, id: string) =>
  hood.cheap === id ? P.cheapMult : hood.premium.includes(id as ProductId) ? P.premiumMult : 1;

/** Buy and sell both derive from one local level, so a same-hood round trip loses by construction. */
export function pricesFor(base: number, valueMult: number, eventMult: number, jitter: number) {
  const level = base * valueMult * eventMult * jitter;
  const buy = Math.max(1, Math.round(level * P.buySide));
  const rawSell = Math.round(level * P.sellSide);
  return { buy, sell: rawSell < buy ? Math.max(1, rawSell) : buy - 1 };
}

export interface Market {
  hoodId: string;
  visit: number;
  shelf: ProductId[];
  buy: Record<string, number>;
  sell: Record<string, number>;
  spike?: ProductId;
  flood?: ProductId;
}

export const guaranteedProducts = (h: Location): ProductId[] =>
  h.guaranteeWholeRing
    ? ([...(h.cheap ? [h.cheap] : []), ...h.premium] as ProductId[])
    : h.cheap
      ? [h.cheap]
      : h.premium.slice(0, 1);

export function resolveMarket(hood: Location, visit: number, rnd: () => number = Math.random): Market {
  const guaranteed = guaranteedProducts(hood);
  const pool = PRODUCTS.map((p) => p.id).filter((id) => !guaranteed.includes(id));
  // shuffle
  for (let i = pool.length - 1; i > 0; i--) {
    const j = Math.floor(rnd() * (i + 1));
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }
  const extras = Math.floor(P.extrasMin + rnd() * (P.extrasMax - P.extrasMin + 1));
  const shelf = ([...guaranteed, ...pool.slice(0, extras)] as ProductId[]).slice(0, PRODUCTS.length);

  let spike: ProductId | undefined;
  let flood: ProductId | undefined;
  if (shelf.length) {
    if (rnd() * 100 < P.spikeChance) spike = shelf[Math.floor(rnd() * shelf.length)];
    if (rnd() * 100 < P.floodChance) {
      const c = shelf[Math.floor(rnd() * shelf.length)];
      if (c !== spike) flood = c;
    }
  }
  const buy: Record<string, number> = {};
  const sell: Record<string, number> = {};
  for (const id of shelf) {
    const eventMult = id === spike ? P.spikeMult : id === flood ? P.floodMult : 1;
    const jitter = P.jitterLow + rnd() * (P.jitterHigh - P.jitterLow);
    const p = pricesFor(productById(id).base, valueMultFor(hood, id), eventMult, jitter);
    buy[id] = p.buy;
    sell[id] = p.sell;
  }
  return { hoodId: hood.id, visit, shelf, buy, sell, spike, flood };
}

// ---- Difficulty (SPEC §4) ----
export const DIFFICULTY: Record<Difficulty, { cash: number; debt: number; label: string; blurb: string }> = {
  easy: { cash: 6000, debt: 5000, label: "Mount Paran", blurb: "Mom and Dad's basement is still an option." },
  normal: { cash: 4000, debt: 10000, label: "East Atlanta", blurb: "The streets know you." },
  hard: { cash: 2000, debt: 15000, label: "Hapeville", blurb: "The clock is ticking." },
};

export const BAG_UPGRADES = [
  { capacity: 250, cost: 400 },
  { capacity: 600, cost: 1000 },
  { capacity: 1000, cost: 3000 },
];

export const ADS = ["ryde", "councilman", "get_higher", "certified_whips", "the_varsity"];
