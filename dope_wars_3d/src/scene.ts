// The 2D map: the v3 highway plate seen straight on, hood rings as HTML, and the
// car sprite sliding the roads between them. No perspective, no lights, no depth.
import * as THREE from "three";
import { type HoodId, type Location } from "./data";

const MAP_W = 62;
// how much of the map fits vertically: the camera is orthographic and looks
// straight down, so this is a flat 2D zoom, not a field of view
const VIEW_H = 74;
const MAP_AR = 1280 / 606;
export const MAP_H = MAP_W * MAP_AR;

const loader = new THREE.TextureLoader();
const tex = (url: string) => {
  const t = loader.load(url);
  t.magFilter = THREE.NearestFilter;
  t.minFilter = THREE.NearestFilter;
  t.colorSpace = THREE.SRGBColorSpace;
  return t;
};

const world = (at: [number, number]): [number, number] => [
  (at[0] / 606 - 0.5) * MAP_W,
  (at[1] / 1280 - 0.5) * MAP_H,
];

export class Diorama {
  scene = new THREE.Scene();
  camera: THREE.OrthographicCamera;
  renderer: THREE.WebGLRenderer;
  private nodes = new Map<HoodId, { at: [number, number]; el: HTMLDivElement; on: boolean }>();
  private overlay: HTMLDivElement;
  private tmp = new THREE.Vector3();
  private car!: THREE.Sprite;
  private frames: THREE.Texture[] = [];
  private carPos = new THREE.Vector3();
  private camTarget = new THREE.Vector3();
  private camLook = new THREE.Vector3();
  private travelling = false;
  private t0 = 0;
  private from = new THREE.Vector3();
  private to = new THREE.Vector3();
  private dur = 2.4;
  private frameClock = 0;
  onPick: (id: HoodId) => void = () => {};
  onArrive: () => void = () => {};

  constructor(canvas: HTMLCanvasElement, hoods: Location[]) {
    // no antialiasing: the map plate and sprites are nearest-neighbour pixel art
    // and AA only softens the edges it is supposed to keep hard
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: false, alpha: true });
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    this.camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0.1, 1000);
    // transparent, so the CSS glow behind the canvas shows past the map edge
    this.scene.background = null;

    const map = new THREE.Mesh(
      new THREE.PlaneGeometry(MAP_W, MAP_H),
      // plain, not additive: the plate is the Flutter map as-is — black ground,
      // neon roads, nothing washing it out
      new THREE.MeshBasicMaterial({ map: tex("assets/images/map_background_v3.jpg") }),
    );
    map.rotation.x = -Math.PI / 2;
    this.scene.add(map);

    // Map nodes are HTML, not meshes: the Flutter build draws them as a 2px
    // ring with a label pill under it, and sprites in a tilted camera can't
    // hold that size or that crispness. Same circle, same pill, project the
    // coordinate every frame.
    this.overlay = document.createElement("div");
    this.overlay.id = "nodes";
    document.body.appendChild(this.overlay);
    for (const h of hoods) {
      const [x, z] = world(h.at);
      const el = document.createElement("div");
      el.className = "node";
      el.style.setProperty("--c", h.accent);
      el.innerHTML = `<span class="dot"></span><span class="ring"></span><b>${h.name}</b>`;
      el.addEventListener("click", () => !this.travelling && this.onPick(h.id));
      this.overlay.appendChild(el);
      this.nodes.set(h.id, { at: [x, z], el, on: false });
    }

    for (let i = 0; i < 8; i++) this.frames.push(tex(`assets/images/travel/frames/drive_${i}.png`));
    this.car = new THREE.Sprite(
      new THREE.SpriteMaterial({ map: this.frames[0], transparent: true, depthTest: false, depthWrite: false }),
    );
    this.car.scale.set(4, 4, 1);
    this.car.visible = false;
    this.car.renderOrder = 10;
    this.scene.add(this.car);

    this.resize();
    addEventListener("resize", () => this.resize());

    // opening shot: high and wide, then settle on the current hood
    this.camTarget.set(0, 3.4, 0);
    this.camLook.set(0, 34, 120);
    this.animate(0);
  }

  private resize() {
    const w = innerWidth;
    const h = innerHeight;
    this.renderer.setSize(w, h, false);
    const half = VIEW_H / 2;
    this.camera.left = -half * (w / h);
    this.camera.right = half * (w / h);
    this.camera.top = half;
    this.camera.bottom = -half;
    this.camera.updateProjectionMatrix();
  }

  focus(id: HoodId, instant = false) {
    const n = this.nodes.get(id);
    if (!n) return;
    const [x, z] = n.at;
    this.camTarget.set(x, 3.4, z);
    if (instant) this.camLook.copy(this.camTarget);
  }

  travel(fromId: HoodId, toId: HoodId, method: "marta" | "ryde" | "drive"): Promise<void> {
    const a = this.nodes.get(fromId)!;
    const b = this.nodes.get(toId)!;
    this.from.set(a.at[0], 0, a.at[1]);
    this.to.set(b.at[0], 0, b.at[1]);
    this.carPos.copy(this.from);
    this.travelling = true;
    this.t0 = performance.now();
    // MARTA is the slow, cheap route; driving is quick and sketchy.
    this.dur = method === "marta" ? 2.9 : method === "ryde" ? 2.4 : 1.9;
    this.car.visible = true;
    this.focus(toId);
    return new Promise((res) => {
      this.onArrive = () => {
        this.car.visible = false;
        res();
      };
    });
  }

  private animate(now: number) {
    requestAnimationFrame((t) => this.animate(t));
    const dt = Math.min(0.05, (now - this.t0) / 1000);

    if (this.travelling) {
      const p = Math.min(1, (now - this.t0) / (this.dur * 1000));
      const e = p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2;
      this.carPos.lerpVectors(this.from, this.to, e);
      this.car.position.copy(this.carPos);
      this.frameClock += dt;
      if (this.frameClock > 0.07) {
        this.frameClock = 0;
        const i = (this.frames.indexOf(this.car.material.map!) + 1) % 8;
        this.car.material.map = this.frames[i];
        this.car.material.needsUpdate = true;
      }
      if (p >= 1) {
        this.travelling = false;
        this.onArrive();
      }
    }

    // current hood's ring breathes
    // Nodes ride on top of the map: project each hood to the screen and place
    // its ring there. Current hood gets the pulsing ring, the rest stay quiet.
    const placed: { el: HTMLDivElement; at: [number, number]; x: number; y: number; half: number }[] = [];
    for (const n of this.nodes.values()) {
      this.tmp.set(n.at[0], 0.1, n.at[1]).project(this.camera);
      // keep the name pill on screen: edge hoods used to lose half their label
      const half = (n.el.querySelector("b")!.offsetWidth || 34) / 2 + 2;
      placed.push({
        el: n.el,
        at: n.at,
        x: Math.min(innerWidth - half, Math.max(half, (this.tmp.x * 0.5 + 0.5) * innerWidth)),
        y: (-this.tmp.y * 0.5 + 0.5) * innerHeight,
        half,
      });
    }
    // Midtown / Little Five Points / Decatur sit close together, so any label that
    // would land on an earlier one drops below its ring instead.
    placed.forEach((p, i) => {
      const low = placed.slice(0, i).some((q) => Math.abs(p.x - q.x) < p.half + q.half && Math.abs(p.y - q.y) < 24);
      p.el.classList.toggle("low", low);
      p.el.style.transform = `translate(-50%, -50%) translate(${p.x.toFixed(1)}px, ${p.y.toFixed(1)}px)`;
      const active = Math.abs(p.at[0] - this.camTarget.x) < 0.5 && Math.abs(p.at[1] - this.camTarget.z) < 0.5;
      p.el.classList.toggle("on", active);
    });

    this.camLook.lerp(this.camTarget, this.travelling ? 0.04 : 0.08);
    // straight down, no tilt and no z offset: the plate stays flat, square-on and
    // pixel-identical to the artwork. Anything else is perspective by another name.
    const camPos = new THREE.Vector3(this.camLook.x, 200, this.camLook.z);
    this.camera.position.lerp(camPos, 0.08);
    this.camera.lookAt(this.camLook.x, 0, this.camLook.z);
    this.renderer.render(this.scene, this.camera);
  }
}
