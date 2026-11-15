// The diorama: the v3 highway map as a glowing tabletop, one isometric sprite per
// hood standing on it, and the car sliding the roads between them.
import * as THREE from "three";
import { type HoodId, type Location } from "./data";

const MAP_W = 62;
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
  camera: THREE.PerspectiveCamera;
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
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    this.camera = new THREE.PerspectiveCamera(42, 1, 0.5, 500);
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
    this.camera.aspect = w / h;
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
      this.carPos.y = 2 + Math.sin(e * Math.PI) * 3.5;
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
    for (const n of this.nodes.values()) {
      this.tmp.set(n.at[0], 0.1, n.at[1]).project(this.camera);
      // keep the name pill on screen: edge hoods used to lose half their label
      const half = (n.el.querySelector("b")!.offsetWidth || 34) / 2 + 2;
      const x = Math.min(innerWidth - half, Math.max(half, (this.tmp.x * 0.5 + 0.5) * innerWidth));
      const y = (-this.tmp.y * 0.5 + 0.5) * innerHeight;
      n.el.style.transform = `translate(-50%, -100%) translate(${x.toFixed(1)}px, ${y.toFixed(1)}px)`;
      const active = Math.abs(n.at[0] - this.camTarget.x) < 0.5 && Math.abs(n.at[1] - this.camTarget.z) < 0.5;
      if (active !== n.on) {
        n.on = active;
        n.el.classList.toggle("on", active);
      }
    }

    this.camLook.lerp(this.camTarget, this.travelling ? 0.04 : 0.08);
    // near-top-down, wide enough to read the whole web of roads like the
    // Flutter map does. The tilt is fake perspective, not a real 3/4 view.
    const camPos = new THREE.Vector3(this.camLook.x, this.camLook.y + 90, this.camLook.z + 16);
    this.camera.position.lerp(camPos, 0.08);
    this.camera.lookAt(this.camLook.x, this.camLook.y + 0.6, this.camLook.z);
    this.renderer.render(this.scene, this.camera);
  }
}
