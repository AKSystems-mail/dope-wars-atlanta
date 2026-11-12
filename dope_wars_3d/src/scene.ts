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

function label(text: string, color: string) {
  const c = document.createElement("canvas");
  c.width = 512;
  c.height = 96;
  const g = c.getContext("2d")!;
  g.fillStyle = "rgba(8,6,14,.82)";
  g.beginPath();
  g.roundRect(18, 14, 476, 68, 10);
  g.fill();
  g.strokeStyle = color;
  g.lineWidth = 3;
  g.stroke();
  g.font = "bold 40px ui-monospace, monospace";
  g.textAlign = "center";
  g.textBaseline = "middle";
  g.shadowColor = color;
  g.shadowBlur = 18;
  g.fillStyle = "#fff";
  g.fillText(text.toUpperCase(), 256, 48);
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: t, transparent: true, depthWrite: false }));
  s.scale.set(9, 1.7, 1);
  return s;
}

export class Diorama {
  scene = new THREE.Scene();
  camera: THREE.PerspectiveCamera;
  renderer: THREE.WebGLRenderer;
  private nodes = new Map<HoodId, { group: THREE.Group; ring: THREE.Mesh; label: THREE.Sprite }>();
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

    // The v3 art paints land pure black and roads neon, so it goes on last and
    // additively: a slate table under it gives the city ground, the roads still
    // burn through. Same texture, two materials — no new art.
    const land = new THREE.Mesh(
      new THREE.PlaneGeometry(MAP_W * 1.4, MAP_H * 1.4),
      new THREE.MeshBasicMaterial({ color: "#171c2b" }),
    );
    land.rotation.x = -Math.PI / 2;
    land.position.y = -0.05;
    this.scene.add(land);

    const map = new THREE.Mesh(
      new THREE.PlaneGeometry(MAP_W, MAP_H),
      new THREE.MeshBasicMaterial({
        map: tex("assets/images/map_background_v3.jpg"),
        blending: THREE.AdditiveBlending,
        depthWrite: false,
      }),
    );
    map.rotation.x = -Math.PI / 2;
    this.scene.add(map);

    this.scene.add(new THREE.AmbientLight("#8899ff", 1.1));
    const key = new THREE.DirectionalLight("#ffffff", 1.6);
    key.position.set(-30, 60, 25);
    this.scene.add(key);
    const neon = new THREE.PointLight("#00ff9d", 120, 90, 2);
    neon.position.set(0, 22, 0);
    this.scene.add(neon);

    for (const h of hoods) {
      const [x, z] = world(h.at);
      const group = new THREE.Group();
      group.position.set(x, 0, z);

      // flat pixel art, not an extruded block: the Flutter build drew these as
      // 2D images on a map and that's the look we're keeping. Sprite faces the
      // camera, so it reads as the same art from any angle.
      const face = new THREE.Sprite(
        new THREE.SpriteMaterial({ map: tex(`assets/sprites/${h.id}.png`), transparent: true, depthWrite: false }),
      );
      const H = (208 / 224) * 8;
      face.scale.set(8, H, 1);
      face.center.set(0.5, 0);
      face.position.y = 0.1;
      face.userData.hood = h.id;
      group.add(face);

      const ring = new THREE.Mesh(
        new THREE.RingGeometry(4.2, 4.9, 48),
        new THREE.MeshBasicMaterial({ color: new THREE.Color(h.accent), transparent: true, opacity: 0.5, side: THREE.DoubleSide }),
      );
      ring.rotation.x = -Math.PI / 2;
      ring.position.y = 0.1;
      group.add(ring);

      const lb = label(h.name, h.accent);
      lb.position.set(0, H + 2.6, 0);
      group.add(lb);

      this.scene.add(group);
      this.nodes.set(h.id, { group, ring, label: lb });
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
    canvas.addEventListener("pointerdown", (e) => this.pick(e));

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

  private pick(e: PointerEvent) {
    if (this.travelling) return;
    const r = this.renderer.domElement.getBoundingClientRect();
    const p = new THREE.Vector2(
      ((e.clientX - r.left) / r.width) * 2 - 1,
      -((e.clientY - r.top) / r.height) * 2 + 1,
    );
    const ray = new THREE.Raycaster();
    ray.setFromCamera(p, this.camera);
    const hits = ray.intersectObjects(
      [...this.nodes.values()].flatMap((n) => n.group.children),
      false,
    );
    for (const hit of hits) {
      const id = hit.object.userData.hood as HoodId | undefined;
      if (id) {
        this.onPick(id);
        return;
      }
    }
  }

  focus(id: HoodId, instant = false) {
    const n = this.nodes.get(id);
    if (!n) return;
    const [x, , z] = n.group.position.toArray();
    this.camTarget.set(x, 3.4, z);
    if (instant) this.camLook.copy(this.camTarget);
  }

  travel(fromId: HoodId, toId: HoodId, method: "marta" | "ryde" | "drive"): Promise<void> {
    const a = this.nodes.get(fromId)!;
    const b = this.nodes.get(toId)!;
    this.from.copy(a.group.position);
    this.to.copy(b.group.position);
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
    const pulse = 0.45 + Math.sin(now / 420) * 0.25;
    for (const n of this.nodes.values()) {
      const active = Math.abs(n.group.position.x - this.camTarget.x) < 0.5 && Math.abs(n.group.position.z - this.camTarget.z) < 0.5;
      (n.ring.material as THREE.MeshBasicMaterial).opacity = active ? pulse + 0.25 : 0.18;
      n.label.material.opacity = active ? 1 : 0.55;
    }

    this.camLook.lerp(this.camTarget, this.travelling ? 0.04 : 0.08);
    // 3/4 view: low enough to see the sides of the buildings, high enough to read the streets
    const camPos = new THREE.Vector3(this.camLook.x, this.camLook.y + 40, this.camLook.z + 16);
    this.camera.position.lerp(camPos, 0.08);
    // aim a little high: the HUD and the action bar eat the top and bottom strips
    this.camera.lookAt(this.camLook.x, this.camLook.y + 1.9, this.camLook.z);
    this.renderer.render(this.scene, this.camera);
  }
}
