// Boot: one Game, one Diorama, one UI. The whole app is those three objects
// talking to each other — no router, no store, no framework.
import { Game } from "./game";
import { HOODS } from "./data";
import { Diorama } from "./scene";
import { UI } from "./ui";

const KEY = "dw3d_save";
const canvas = document.getElementById("c") as HTMLCanvasElement;
const dio = new Diorama(canvas, HOODS);

let game = new Game();
const saved = localStorage.getItem(KEY);
if (saved) {
  try {
    game = Game.fromJSON(JSON.parse(saved)) ?? game;
  } catch {
    localStorage.removeItem(KEY);
  }
}

// ---------- audio ----------
const files: Record<string, string> = {
  cash: "assets/sounds/cash_register.wav",
  cash_register: "assets/sounds/cash_register.wav",
  car_horn: "assets/sounds/car_horn.wav",
  marta_chime: "assets/sounds/marta_chime.wav",
  encounter: "assets/sounds/encounter.wav",
  weapon_fire: "assets/sounds/weapon_fire.wav",
};
const pool: Record<string, HTMLAudioElement> = {};
const music = new Audio("assets/sounds/night_loop.mp3");
music.loop = true;
music.volume = 0.35;

const audio = {
  play(name: string) {
    if (!game.s.sound) return;
    const src = files[name];
    if (!src) return;
    const el = (pool[name] ??= new Audio(src));
    el.currentTime = 0;
    void el.play().catch(() => {});
  },
  syncMusic() {
    if (game.s.music) void music.play().catch(() => {});
    else music.pause();
  },
};

// ---------- wiring ----------
const ui = new UI(game, dio);

const persist = () => {
  try {
    localStorage.setItem(KEY, JSON.stringify(game.toJSON()));
  } catch {
    /* private mode: play on without a save */
  }
};

let lastLoc = "";
const bind = (g: Game) => {
  g.sfx = (n) => audio.play(n);
  g.onChange = () => {
    if (g.s.loc !== lastLoc) {
      lastLoc = g.s.loc;
      dio.focus(g.s.loc);
    }
    ui.render();
    persist();
  };
  lastLoc = g.s.loc;
};
bind(game);

ui.onTravel = async (to, method) => {
  if (!game.canTravel(to, method)) return;
  const from = game.s.loc;
  ui.panel = null;
  ui.render();
  await dio.travel(from, to, method);
  game.travel(to, method);
  ui.render();
  persist();
};

ui.onLayLow = () => {
  game.layLow();
  ui.render();
  persist();
};

ui.onNewGame = (sel) => {
  game = Game.newGame(sel.difficulty, sel.days, sel.mode);
  ui.game = game;
  ui.started = true;
  bind(game);
  dio.focus(game.s.loc, true);
  ui.render();
  persist();
};

if (saved) {
  // a save exists: show the title with CONTINUE rather than dumping them mid-run
  dio.focus(game.s.loc, true);
} else {
  dio.focus(game.s.loc, true);
}
// handy for poking the engine from the console / automated checks
(globalThis as any).__dw = { get game() { return game; }, ui, dio, bind };

audio.syncMusic();
addEventListener("pointerdown", () => audio.syncMusic(), { once: true });
setInterval(() => audio.syncMusic(), 3000);
