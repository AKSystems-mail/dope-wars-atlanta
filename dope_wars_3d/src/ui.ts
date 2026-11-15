// DOM face of the game: HUD, action bar, sheets and full-screen moments.
// Deliberately one file of template strings — there is no framework here worth
// the install, and the Flutter layout it mirrors is a stack of small popups.
import {
  BAG_UPGRADES,
  DIFFICULTY,
  HOODS,
  PRODUCTS,
  WEAPONS,
  productById,
  reputationLine,
  type Difficulty,
  type HoodId,
  type Mode,
} from "./data";
import type { Game, Method } from "./game";
import type { Diorama } from "./scene";

const $ = (id: string) => document.getElementById(id)!;
const money = (n: number) => "$" + Math.round(n).toLocaleString();
// the HUD cell is ~90px wide at phone size; long words wrap badly, so shorten
const TIME_SHORT: Record<string, string> = {
  "Late Night": "LATE",
  Morning: "MORN",
  Afternoon: "AFTN",
  Evening: "EVE",
  Night: "NIGHT",
};

export class UI {
  hud = $("hud");
  bar = $("bar");
  sheet = $("sheet");
  fx = $("fx");
  panel: string | null = null;
  started = false;
  travelTarget: HoodId | null = null;
  sel: { difficulty: Difficulty; days: number; mode: Mode } = { difficulty: "normal", days: 30, mode: "classic" };
  onTravel: (to: HoodId, method: Method) => void = () => {};
  onNewGame: (sel: { difficulty: Difficulty; days: number; mode: Mode }) => void = () => {};
  onLayLow: () => void = () => {};

  constructor(
    public game: Game,
    public dio: Diorama,
  ) {
    document.addEventListener("click", (e) => {
      const el = (e.target as HTMLElement).closest("[data-a]") as HTMLElement | null;
      if (!el) return;
      e.preventDefault();
      this.click(el.dataset.a!, el.dataset.v ?? "");
    });
    this.fx.addEventListener("click", () => {
      if (this.game.ad) {
        this.game.dismissAd();
        this.render();
      }
    });
    this.render();
  }

  // ---------- shell ----------
  render() {
    const g = this.game;
    const s = g.s;
    if (!s) return;
    // Same strip the Flutter PixelHud draws: coloured facts in a wrap row,
    // no key/value grid, heat only in Progressive.
    const lateDay = s.day / s.maxDays > 0.75;
    const heatColor =
      g.heatLabel === "Hot" ? "red" : g.heatLabel === "Warm" ? "gold" : "dim";
    const bagPct = g.invCount / s.bag;
    this.hud.innerHTML = `
      <span class="${lateDay ? "red" : "green"}">DAY ${s.day}/${s.maxDays}</span>
      ${g.progressive ? `<span class="${heatColor}">HEAT ${g.heatLabel.toUpperCase()}</span>` : ""}
      <span class="gold">${TIME_SHORT[g.timeLabel] ?? g.timeLabel}</span>
      ${s.bank > 0 ? `<span class="blue">B${money(s.bank)}</span>` : ""}
      <span class="gold">${money(s.cash)}</span>
      ${s.debt > 0 ? `<span class="red">${money(s.debt)}</span>` : ""}
      <span class="${bagPct >= 0.8 ? "gold" : "dim"}">${g.invCount}/${s.bag}</span>`;

    const b: string[] = [];
    const btn = (a: string, label: string, hot = false, v = "") =>
      b.push(`<button class="${hot ? "hot" : ""}" data-a="${a}" ${v ? `data-v="${v}"` : ""}>${label}</button>`);
    btn("panel", "SHOP", false, "shop");
    btn("panel", "MAP", false, "map");
    btn("panel", "BAG", false, "bag");
    if (g.hood.bank) btn("panel", "BANK", false, "bank");
    if (g.hood.weapons) btn("panel", "GUNS", false, "weapons");
    if (g.hood.councilman) btn("panel", "COUNCIL", false, "councilman");
    if (g.hood.bookbag) btn("panel", "BOOKBAG", false, "bookbag");
    btn("laylow", "LAY LOW");
    btn("panel", "MENU", false, "settings");
    this.bar.innerHTML = b.join("");

    this.renderSheet();
    this.renderFx();
  }

  private panelShell(title: string, sub: string, body: string) {
    return `<div class="panel"><header><div><h2>${title}</h2>${sub ? `<div class="sub">${sub}</div>` : ""}</div>
      <button class="x" data-a="close">✕</button></header><div class="body">${body}</div></div>`;
  }

  renderSheet() {
    if (!this.panel) {
      this.sheet.hidden = true;
      this.sheet.innerHTML = "";
      return;
    }
    this.sheet.hidden = false;
    const g = this.game;
    const p = this.panel;
    let html = "";
    if (p === "shop") html = this.shop();
    else if (p === "map") html = this.map();
    else if (p === "bag") html = this.bag();
    else if (p === "bank") html = this.bank();
    else if (p === "councilman") html = this.councilman();
    else if (p === "weapons") html = this.weapons();
    else if (p === "bookbag") html = this.bookbag();
    else if (p === "settings") html = this.settings();
    this.sheet.innerHTML = html;
    void g;
  }

  renderFx() {
    const g = this.game;
    let html = "";
    if (!this.started) {
      html = this.titleScreen();
    } else if (g.overMessage) {
      html = `<div class="modal"><h2>${g.overMessage.split("\n")[0]}</h2><pre>${g.overMessage
        .split("\n")
        .slice(1)
        .join("\n")}</pre>
        <div class="choices">
          <button class="btn green" data-a="newgame">NEW GAME</button>
          ${g.s.cash <= 0 && !g.s.bailoutUsed ? `<button class="btn gold" data-a="bailout">BAILOUT ($500)</button>` : ""}
        </div></div>`;
    } else if (g.encounter) {
      const e = g.encounter;
      html = `<div class="modal">
        ${e.image ? `<img src="${e.image}" alt="" />` : ""}
        <pre>${e.text}</pre>
        <div class="choices">
          ${
            e.choices
              ? e.choices
                  .map(
                    (c, i) =>
                      `<button class="btn" data-a="choice" data-v="${i}" style="border-color:${c.color ?? "#3d3450"};color:${c.color ?? "#fff"}">${c.label}</button>`,
                  )
                  .join("")
              : `<button class="btn green" data-a="dismiss">CONTINUE</button>`
          }
        </div></div>`;
    } else if (g.ad) {
      html = `<div class="modal ad">
        <img src="assets/ads/${g.ad}.png" alt="" />
        <div class="hint">TAP TO SKIP</div>
      </div>`;
    }
    this.fx.hidden = !html;
    this.fx.innerHTML = html;
  }

  // ---------- screens ----------
  private titleScreen() {
    const d = this.sel;
    const hasSave = !!localStorage.getItem("dw3d_save");
    // Boot screen copied from the Flutter build: typed terminal block, then the
    // "choose your run" cards, then PRESS START with CONTINUE underneath it.
    const card = (a: string, v: string, emoji: string, title: string, sub: string, on = false) =>
      `<button class="card ${on ? "on" : ""}" data-a="${a}"${v ? ` data-v="${v}"` : ""}>
        <span class="ico">${emoji}</span>
        <span class="txt"><b>${title}</b><i>${sub}</i></span>
      </button>`;
    return `<div class="modal title boot">
      <pre class="term">DOPE WARS ATL
LOADING...
v1.0.0

ATLANTA, GA
EST. 2026

INSERT COIN</pre>
      <p>CHOOSE YOUR RUN</p>
      ${hasSave ? card("wipe", "", "🗑️", "START OVER", "Discard the saved run and choose a fresh mode") : ""}
      ${card("setmode", "classic", "🎯", "CLASSIC", "The whole city is open. Beat the calendar and bank the most.", d.mode === "classic")}
      ${card("setmode", "progressive", "🗺️", "PROGRESSIVE", "Start with two hoods. Earn the rest, then own the city.", d.mode === "progressive")}
      <div class="opts"><span class="cap">START</span><div class="grp">
        ${["easy", "normal", "hard"]
          .map((x) => `<button class="btn ${d.difficulty === x ? "green" : ""}" data-a="setdiff" data-v="${x}">${DIFFICULTY[x as Difficulty].label.toUpperCase()}</button>`)
          .join("")}
      </div></div>
      <div class="opts"><span class="cap">DAYS</span><div class="grp">
        ${[30, 60, 90].map((n) => `<button class="btn ${d.days === n ? "green" : ""}" data-a="setdays" data-v="${n}">${n}</button>`).join("")}
      </div></div>
      <div class="choices col">
        <button class="pstart" data-a="start">PRESS START</button>
        ${hasSave ? `<button class="btn cont" data-a="resume">CONTINUE</button>` : ""}
      </div>
      <div class="made">cash ${money(DIFFICULTY[d.difficulty].cash)} · debt ${money(DIFFICULTY[d.difficulty].debt)}</div>
    </div>`;
  }

  private shop() {
    const g = this.game;
    const m = g.market;
    const s = g.s;
    const rows = m.shelf
      .map((id) => {
        const p = productById(id);
        const note = m.spike === id ? "🔥 DEMAND SPIKE" : m.flood === id ? "🌊 MARKET FLOOD" : "";
        const held = s.inv[id] ?? 0;
        const buyN = (n: number) => n;
        return `<div class="row">
          <div class="grow">
            <div class="name">${p.emoji} ${p.name} <span style="color:#9ca3af;font-weight:400">· ${held}</span></div>
            <div class="meta">buy <span class="price">${money(m.buy[id])}</span> · sell <span class="price sell">${money(m.sell[id])}</span></div>
            ${note ? `<div class="note">${note}</div>` : ""}
          </div>
          <button class="btn green" data-a="buy" data-v="${id}:1">BUY 1</button>
          <button class="btn green" data-a="buy" data-v="${id}:${buyN(10)}">BUY 10</button>
          <button class="btn gold" data-a="sell" data-v="${id}:1">SELL 1</button>
          <button class="btn gold" data-a="sellall" data-v="${id}">ALL</button>
        </div>`;
      })
      .join("");
    // Header is the hood itself, like the Flutter market screen: the name is the
    // title and its reputation line is the subtitle.
    return this.panelShell(
      g.hood.name,
      `${reputationLine(g.hood)} · bag ${g.invCount}/${s.bag}`,
      rows || `<div class="empty">Nobody's selling here.</div>`,
    );
  }

  private map() {
    const g = this.game;
    const rows = HOODS.filter((h) => h.id !== g.s.loc)
      .map((h) => {
        const locked = !g.isUnlocked(h.id);
        const byMarta = g.hood.marta.includes(h.id);
        const byRoad = g.hood.highway.includes(h.id);
        const marta = byMarta && !locked ? `<button class="btn green" data-a="travel" data-v="${h.id}:marta">MARTA $5</button>` : "";
        const ryde = byRoad && !locked ? `<button class="btn gold" data-a="travel" data-v="${h.id}:ryde">RYDE ${money(g.costOf("ryde"))}</button>` : "";
        const drive = byRoad && !locked ? `<button class="btn pink" data-a="travel" data-v="${h.id}:drive">DRIVE $20</button>` : "";
        return `<div class="row" style="border-color:${h.accent}55">
          <div class="grow">
            <div class="name" style="color:${h.accent}">${h.name} ${locked ? "🔒" : ""}</div>
            <div class="meta">${g.s.known.includes(h.id) ? reputationLine(h) : "Unknown market — go see."}</div>
          </div>
          ${locked ? `<span class="meta">informant only</span>` : marta + ryde + drive}
        </div>`;
      })
      .join("");
    return this.panelShell("ATLANTA", `${g.timeLabel} · day ${g.s.day} of ${g.s.maxDays} · every trip is a day`, rows);
  }

  private bag() {
    const g = this.game;
    const s = g.s;
    const inv = Object.entries(s.inv).filter(([, q]) => q > 0);
    const rows = inv
      .map(([id, qty]) => {
        const p = productById(id);
        return `<div class="row">
          <div class="grow"><div class="name">${p.emoji} ${p.name}</div>
          <div class="meta">${qty} units · base ${money(p.base)}${s.inv[id] ? "" : ""}</div></div>
          <button class="btn" data-a="dump" data-v="${id}:5">DUMP 5</button>
          <button class="btn" data-a="dump" data-v="${id}:25">DUMP 25</button>
        </div>`;
      })
      .join("");
    const guns = s.weapons
      .map((w) => {
        const def = WEAPONS.find((x) => x.id === w.id)!;
        return `<div class="row">
          <div class="grow"><div class="name">${def.emoji} ${def.name}${w.equipped ? " · EQUIPPED" : ""}</div>
          <div class="meta">${def.maxDurability > 5 ? "unbreakable" : `${w.durability}/${def.maxDurability} uses`} · ${Math.round(def.killChance * 100)}% win</div></div>
          ${w.equipped ? "" : `<button class="btn green" data-a="equip" data-v="${w.id}">EQUIP</button>`}
        </div>`;
      })
      .join("");
    return this.panelShell(
      "BOOKBAG",
      `${g.invCount}/${s.bag} slots · dumping cools heat (5 units minimum)`,
      (rows || `<div class="empty">Bag is empty.</div>`) + `<h2 style="margin-top:8px">POCKET</h2>` + guns,
    );
  }

  private bank() {
    const s = this.game.s;
    return this.panelShell(
      "MIDTOWN BANK",
      "1% daily interest · depositing cools 2 heat",
      `<div class="row"><div class="grow"><div class="name">Balance</div><div class="meta">earning 1% a day</div></div><span class="price">${money(s.bank)}</span></div>
       <input id="amt" type="number" inputmode="numeric" placeholder="amount" value="500" />
       <div class="choices" style="display:flex;gap:6px;flex-wrap:wrap">
         <button class="btn green" data-a="deposit" data-v="amt">DEPOSIT</button>
         <button class="btn gold" data-a="withdraw" data-v="amt">WITHDRAW</button>
         <button class="btn" data-a="deposit" data-v="all">DEPOSIT ALL</button>
         <button class="btn" data-a="withdraw" data-v="all">WITHDRAW ALL</button>
       </div>`,
    );
  }

  private councilman() {
    const g = this.game;
    const s = g.s;
    return this.panelShell(
      "THE COUNCILMAN",
      "2% daily interest on debt · paying cools heat",
      `<div class="row"><div class="grow"><div class="name">Owed</div><div class="meta">${
        s.debt > 0 ? `grows ${money(s.debt * 0.02)} a day` : "square with the city"
      }</div></div><span class="price ${s.debt > 0 ? "sell" : ""}">${money(s.debt)}</span></div>
       <div class="row">
         <div class="grow"><div class="name">Pay down</div><div class="meta">clear it and GSP chases drop to 2%</div></div>
         <button class="btn green" data-a="pay" data-v="1000">$1K</button>
         <button class="btn green" data-a="pay" data-v="5000">$5K</button>
         <button class="btn green" data-a="pay" data-v="all">ALL</button>
       </div>
       <div class="row">
         <div class="grow"><div class="name">Borrow</div><div class="meta">cash now, 2% a day forever</div></div>
         <button class="btn pink" data-a="borrow" data-v="1000">$1K</button>
         <button class="btn pink" data-a="borrow" data-v="5000">$5K</button>
         <button class="btn pink" data-a="borrow" data-v="10000">$10K</button>
       </div>`,
    );
  }

  private weapons() {
    const g = this.game;
    const rows = WEAPONS.filter((w) => w.id !== "fists")
      .map((w) => {
        const owned = g.s.weapons.find((s) => s.id === w.id);
        return `<div class="row">
          <div class="grow"><div class="name">${w.emoji} ${w.name}</div>
          <div class="meta">${Math.round(w.killChance * 100)}% win · ${w.maxDurability} uses${
            owned ? ` · owned (${owned.durability})` : ""
          }</div></div>
          <span class="price">${money(w.price)}</span>
          <button class="btn green" data-a="weapon" data-v="${w.id}" ${
            g.s.cash < w.price || (g.s.weapons.length >= 3 && !owned) ? "disabled" : ""
          }>${owned ? "RECHARGE" : "BUY"}</button>
        </div>`;
      })
      .join("");
    return this.panelShell("WEST END ARMORY", `3 slots · equipped: ${g.equippedWeapon.name}`, rows);
  }

  private bookbag() {
    const g = this.game;
    const rows = BAG_UPGRADES.map((u) => {
      const owned = g.s.bag >= u.capacity;
      const can = g.s.cash >= u.cost && !owned;
      return `<div class="row">
        <div class="grow"><div class="name">${u.capacity} slots</div><div class="meta">${
          owned ? "already yours" : `upgrade from ${g.s.bag}`
        }</div></div>
        <span class="price">${money(u.cost)}</span>
        <button class="btn green" data-a="upgrade" data-v="${u.capacity}:${u.cost}" ${can ? "" : "disabled"}>BUY</button>
      </div>`;
    }).join("");
    return this.panelShell("LITTLE FIVE", `bookbag ${g.invCount}/${g.s.bag}`, rows);
  }

  private settings() {
    const g = this.game;
    const s = g.s;
    const onoff = (a: string, on: boolean, label: string) =>
      `<button class="btn ${on ? "green" : ""}" data-a="${a}">${label}: ${on ? "ON" : "OFF"}</button>`;
    return this.panelShell(
      "SETTINGS",
      `${DIFFICULTY[s.difficulty].label} · ${s.mode} · day ${s.day}/${s.maxDays}`,
      `<div class="choices" style="display:flex;gap:6px;flex-wrap:wrap">
        ${onoff("togglesound", s.sound, "SOUND")}
        ${onoff("togglemusic", s.music, "MUSIC")}
      </div>
      <div class="choices" style="display:flex;gap:6px;flex-wrap:wrap">
        ${[30, 60, 90].map((d) => `<button class="btn ${s.maxDays === d ? "green" : ""}" data-a="days" data-v="${d}">${d} DAYS</button>`).join("")}
      </div>
      <div class="choices" style="display:flex;gap:6px;flex-wrap:wrap">
        ${(["easy", "normal", "hard"] as Difficulty[])
          .map((d) => `<button class="btn ${s.difficulty === d ? "green" : ""}" data-a="difficulty" data-v="${d}">${DIFFICULTY[d].label.toUpperCase()}</button>`)
          .join("")}
      </div>
      <div class="choices" style="display:flex;gap:6px;flex-wrap:wrap">
        ${(["classic", "progressive"] as Mode[])
          .map((m) => `<button class="btn ${s.mode === m ? "green" : ""}" data-a="mode" data-v="${m}">${m.toUpperCase()}</button>`)
          .join("")}
      </div>
      <div class="meta" style="color:#9ca3af;font-size:10px">Changing difficulty, days or mode starts a new run.</div>
      <div class="choices" style="display:flex;gap:6px">
        <button class="btn pink" data-a="newgame">NEW GAME</button>
        <button class="btn" data-a="close">CLOSE</button>
      </div>`,
    );
  }

  // ---------- interactions ----------
  click(a: string, v: string) {
    const g = this.game;
    const s = g.s;
    const num = (x: string, fallback = 0) => {
      if (x === "all") return Number.MAX_SAFE_INTEGER;
      const el = document.getElementById("amt") as HTMLInputElement | null;
      if (x === "amt") return Math.max(0, parseInt(el?.value ?? "0", 10) || fallback);
      return parseInt(x, 10) || fallback;
    };

    switch (a) {
      case "panel":
        this.panel = v;
        this.render();
        return;
      case "close":
        this.panel = null;
        this.render();
        return;
      case "start":
      case "newgame":
        this.onNewGame(this.sel);
        this.panel = null;
        this.render();
        return;
      case "wipe":
        localStorage.removeItem("dw3d_save");
        location.reload();
        return;
      case "resume":
        this.started = true;
        this.render();
        return;
      case "setdiff":
        this.sel.difficulty = v as Difficulty;
        this.render();
        return;
      case "setdays":
        this.sel.days = parseInt(v, 10);
        this.render();
        return;
      case "setmode":
        this.sel.mode = v as Mode;
        this.render();
        return;
      case "buy":
        if (!s) return;
        {
          const [id, q] = v.split(":");
          g.buy(id, parseInt(q, 10));
        }
        this.render();
        return;
      case "sell":
      case "sellall":
        if (!s) return;
        {
          const [id, q] = v.split(":");
          g.sell(id, a === "sellall" ? s.inv[id] ?? 0 : parseInt(q, 10));
        }
        this.render();
        return;
      case "dump":
        if (!s) return;
        {
          const [id, q] = v.split(":");
          g.dump(id, parseInt(q, 10));
        }
        this.render();
        return;
      case "deposit":
        if (!s) return;
        g.deposit(v === "all" ? s.cash : num(v));
        this.render();
        return;
      case "withdraw":
        if (!s) return;
        g.withdraw(v === "all" ? s.bank : num(v));
        this.render();
        return;
      case "pay":
        if (!s) return;
        g.payDebt(v === "all" ? s.debt : num(v));
        this.render();
        return;
      case "borrow":
        if (!s) return;
        g.borrow(num(v));
        this.render();
        return;
      case "upgrade":
        if (!s) return;
        {
          const [cap, cost] = v.split(":").map(Number);
          g.upgradeBag(cap, cost);
        }
        this.render();
        return;
      case "weapon":
        if (!s) return;
        {
          const w = WEAPONS.find((x) => x.id === v);
          if (w) g.buyWeapon(w);
        }
        this.render();
        return;
      case "equip":
        g.equipById(v);
        this.render();
        return;
      case "travel":
        if (!s) return;
        {
          const [id, m] = v.split(":");
          this.panel = null;
          this.onTravel(id as HoodId, m as Method);
        }
        return;
      case "laylow":
        this.onLayLow();
        return;
      case "choice":
        if (!g.encounter?.choices) return;
        g.encounter.choices[parseInt(v, 10)].run();
        this.render();
        return;
      case "dismiss":
        g.dismissEncounter();
        this.render();
        return;
      case "bailout":
        g.bailout();
        this.render();
        return;
      case "togglesound":
        if (!s) return;
        g.setSetting({ sound: !s.sound });
        this.render();
        return;
      case "togglemusic":
        if (!s) return;
        g.setSetting({ music: !s.music });
        this.render();
        return;
      case "days":
      case "difficulty":
      case "mode":
        if (!s) return;
        if (!confirm("Changing this starts a new run. Continue?")) return;
        if (a === "days") s.maxDays = parseInt(v, 10);
        if (a === "difficulty") s.difficulty = v as Difficulty;
        if (a === "mode") s.mode = v as Mode;
        this.sel = { difficulty: s.difficulty, days: s.maxDays, mode: s.mode };
        this.onNewGame(this.sel);
        this.render();
        return;
    }
  }
}
