<template>
  <div class="lanyard-container" ref="containerRef" 
    @mousedown="onPointerDown" 
    @touchstart="onPointerDown"
    @mousemove="onPointerMove"
    @touchmove="onPointerMove"
    @mouseup="onPointerUp"
    @touchend="onPointerUp"
    @mouseleave="onPointerUp">
    <canvas ref="canvasRef"></canvas>
    
    <div class="auth-message" v-if="!loading && !isPulled">
      <div class="glow-text">IDENTITY VERIFIED</div>
      <div class="sub-text active-prompt">PULL DOWN TO SECURE ACCESS</div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick } from 'vue';
import * as THREE from 'three';
import RAPIER from '@dimforge/rapier3d-compat';
import { MeshLineGeometry, MeshLineMaterial } from 'meshline';
import logoUrl from '../../assets/logo_full.png';

const props = withDefaults(defineProps<{
  userName?: string;
  userRole?: string;
  position?: [number, number, number];
  gravity?: [number, number, number];
}>(), {
  position: () => [0, 0, 18],
  gravity: () => [0, -40, 0]
});

const emit = defineEmits(['authorized']);

const containerRef = ref<HTMLElement | null>(null);
const canvasRef = ref<HTMLCanvasElement | null>(null);
const loading = ref(true);
const isPulled = ref(false);

let scene: THREE.Scene;
let camera: THREE.PerspectiveCamera;
let renderer: THREE.WebGLRenderer;
let world: RAPIER.World;
let animationFrame: number;
let raycaster = new THREE.Raycaster();
let pointer = new THREE.Vector2();

// Physics & Interaction state
let isDragging = false;
let draggedOffset = new THREE.Vector3();
let dragThreshold = 5.5; // Tension needed to trigger
let currentTension = 0;

// Physics bodies
let fixedBody: RAPIER.RigidBody;
const joints: { body: RAPIER.RigidBody; lerped: THREE.Vector3 }[] = [];
let cardBody: RAPIER.RigidBody;

let cardGroup: THREE.Group;
let ropeMesh: THREE.Mesh;
let clipMesh: THREE.Mesh;
let ropeGeometry: MeshLineGeometry;

// Animation state
let targetY = 11.0; 
let currentAnchorY = 22; 
let isDropping = true;
let pullSpeed = 0;
const pullAccel = 0.8;

const onPointerDown = (e: MouseEvent | TouchEvent) => {
    if (loading.value || isPulled.value || isDropping) return;
    
    const container = containerRef.value;
    if (!container) return;
    const rect = container.getBoundingClientRect();

    let clientX: number, clientY: number;
    if (e instanceof MouseEvent) {
        clientX = e.clientX;
        clientY = e.clientY;
    } else {
        if (!e.touches[0]) return;
        clientX = e.touches[0].clientX;
        clientY = e.touches[0].clientY;
    }

    pointer.x = ((clientX - rect.left) / rect.width) * 2 - 1;
    pointer.y = -((clientY - rect.top) / rect.height) * 2 + 1;

    raycaster.setFromCamera(pointer, camera);
    const intersects = raycaster.intersectObjects([cardGroup], true);

    const firstHit = intersects[0];

    if (firstHit && cardBody) {
        isDragging = true;
        const p = cardBody.translation();
        const worldPos = new THREE.Vector3(p.x, p.y, p.z);
        
        // Calculate offset for natural dragging
        const hitPoint = firstHit.point;
        draggedOffset.copy(hitPoint).sub(worldPos);
        
        cardBody.setBodyType(RAPIER.RigidBodyType.KinematicPositionBased, true);
        document.body.style.cursor = 'grabbing';
    }
};

const onPointerMove = (e: MouseEvent | TouchEvent) => {
    const container = containerRef.value;
    if (!container) return;
    const rect = container.getBoundingClientRect();

    let clientX: number, clientY: number;
    if (e instanceof MouseEvent) {
        clientX = e.clientX;
        clientY = e.clientY;
    } else {
        if (!e.touches[0]) return;
        clientX = e.touches[0].clientX;
        clientY = e.touches[0].clientY;
    }

    pointer.x = ((clientX - rect.left) / rect.width) * 2 - 1;
    pointer.y = -((clientY - rect.top) / rect.height) * 2 + 1;

    if (isDragging && cardBody) {
        // Project mouse to world at card depth
        const vec = new THREE.Vector3(pointer.x, pointer.y, 0.5);
        vec.unproject(camera);
        const dir = vec.clone().sub(camera.position).normalize();
        const distance = -camera.position.z / dir.z; 
        const targetPos = camera.position.clone().add(dir.multiplyScalar(distance));
        
        cardBody.setNextKinematicTranslation({ 
            x: targetPos.x - draggedOffset.x, 
            y: targetPos.y - draggedOffset.y, 
            z: targetPos.z - draggedOffset.z 
        });

        const anchorPos = new THREE.Vector3(0, currentAnchorY, 0);
        const cardPos = new THREE.Vector3(targetPos.x, targetPos.y, targetPos.z);
        currentTension = cardPos.distanceTo(anchorPos);
    } else if (!isPulled.value && !isDropping) {
        // Hover Detection
        raycaster.setFromCamera(pointer, camera);
        const intersects = raycaster.intersectObjects([cardGroup], true);
        document.body.style.cursor = intersects.length > 0 ? 'grab' : 'default';
    }
};

const onPointerUp = () => {
    if (!isDragging) return;
    isDragging = false;
    document.body.style.cursor = 'default';
    if (cardBody) cardBody.setBodyType(RAPIER.RigidBodyType.Dynamic, true);

    // If tensioned enough, fire authorization!
    if (currentTension > 14) { 
        authorize();
    } else {
        // Elastic bounce back
        cardBody.applyImpulse({ x: 0, y: 30, z: -10 }, true);
    }
    currentTension = 0;
};

const authorize = () => {
    if (isPulled.value) return;
    isPulled.value = true;
    
    // Violent upwards snap
    cardBody.applyImpulse({ x: 0, y: 180, z: -40 }, true);
    
    setTimeout(() => {
        emit('authorized');
    }, 2200);
};

const createCardTexture = (name: string, role: string) => {
    const canvas = document.createElement('canvas');
    canvas.width = 1024; canvas.height = 1600;
    const ctx = canvas.getContext('2d');
    if (!ctx) return new THREE.CanvasTexture(canvas);

    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, 1024, 1600);
    
    // Elite Guilloche Pattern
    ctx.strokeStyle = 'rgba(255,140,0,0.06)';
    ctx.lineWidth = 0.8;
    for(let i=0; i<1600; i+=40) {
        ctx.beginPath(); ctx.moveTo(0, i);
        ctx.bezierCurveTo(341, i-60, 682, i+60, 1024, i); ctx.stroke();
    }

    const headerGrad = ctx.createLinearGradient(0,0,0,400); headerGrad.addColorStop(0, '#000000'); headerGrad.addColorStop(1, '#1a1a1a');
    ctx.fillStyle = headerGrad; ctx.fillRect(0, 0, 1024, 400);

    ctx.fillStyle = '#ff8c00'; ctx.font = '900 100px Outfit'; ctx.textAlign = 'left';
    ctx.fillText('HERO FARM', 80, 160);
    ctx.fillStyle = 'rgba(255,255,255,0.4)'; ctx.font = '700 24px JetBrains Mono'; ctx.letterSpacing = '14px';
    ctx.fillText('IDENTITY ACCESS NODE', 80, 240);

    // Photo
    const fx = 80, fy = 480, fw = 400, fh = 500;
    ctx.save();
    ctx.fillStyle = '#f0f0f0'; ctx.beginPath(); ctx.roundRect(fx, fy, fw, fh, 30); ctx.fill();
    ctx.clip();
    ctx.fillStyle = '#d0d0d0';
    ctx.beginPath(); ctx.arc(fx+200, fy+150, 90, 0, Math.PI*2); ctx.fill();
    ctx.beginPath(); ctx.arc(fx+200, fy+450, 220, 0, Math.PI*2); ctx.fill();
    ctx.restore();
    ctx.strokeStyle = '#ff8c00'; ctx.lineWidth = 4; ctx.strokeRect(fx, fy, fw, fh);

    // Identity Labels
    const dx = 530;
    ctx.fillStyle = '#888'; ctx.font = '700 24px JetBrains Mono'; ctx.fillText('IDENTIFIER', dx, 520);
    ctx.fillStyle = '#000'; ctx.font = '900 85px Outfit'; ctx.fillText(name.toUpperCase(), dx, 610);
    ctx.fillStyle = '#888'; ctx.font = '700 24px JetBrains Mono'; ctx.fillText('SECURITY ROLE', dx, 710);
    ctx.fillStyle = '#ff8c00'; ctx.font = '800 45px Outfit'; ctx.fillText(role.toUpperCase(), dx, 780);

    // Access Stamp
    ctx.fillStyle = 'rgba(0,180,100,0.1)'; ctx.roundRect(80, 1050, 864, 120, 20); ctx.fill();
    ctx.fillStyle = '#00ad50'; ctx.font = '900 45px JetBrains Mono'; ctx.textAlign = 'center';
    ctx.fillText('✓ VERIFIED SECURE NODE', 512, 1125);

    // Barcode
    for(let i=0; i<864; i+=12) {
        if(Math.random() > 0.3) { ctx.fillStyle = '#111'; ctx.fillRect(80 + i, 1340, 6, 110); }
    }

    const texture = new THREE.CanvasTexture(canvas);
    texture.anisotropy = 16; texture.needsUpdate = true;
    return texture;
};

const init = async () => {
    try {
        await RAPIER.init();
        if (!canvasRef.value || !containerRef.value) return;

        world = new RAPIER.World({ x: props.gravity[0], y: props.gravity[1], z: props.gravity[2] });
        scene = new THREE.Scene();
        
        const w = containerRef.value.clientWidth;
        const h = containerRef.value.clientHeight;
        camera = new THREE.PerspectiveCamera(28, w / h, 0.1, 1000);
        camera.position.set(props.position[0], props.position[1], props.position[2]);

        renderer = new THREE.WebGLRenderer({ canvas: canvasRef.value, alpha: true, antialias: true });
        renderer.setSize(w, h);
        renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

        // Studio Environment Emulation
        scene.add(new THREE.AmbientLight(0xffffff, 1.2));
        const spot = new THREE.SpotLight(0xffffff, 150);
        spot.position.set(5, 15, 10); spot.angle = 0.5; scene.add(spot);
        
        const fill = new THREE.DirectionalLight(0xff8c00, 1.5);
        fill.position.set(-10, 0, 5); scene.add(fill);

        // CARD IMPLEMENTATION
        const rw = 1.1, rh = 1.7;
        cardGroup = new THREE.Group();
        
        const loader = new THREE.TextureLoader();
        const backLogoTex = loader.load(logoUrl);
        backLogoTex.anisotropy = 16;

        const shell = new THREE.Mesh(new THREE.BoxGeometry(rw * 2, rh * 2, 0.15), new THREE.MeshPhysicalMaterial({ color: 0xffffff, roughness: 0.1, clearcoat: 1 }));
        
        // Front Face
        const face = new THREE.Mesh(new THREE.PlaneGeometry(rw * 2 - 0.05, rh * 2 - 0.05), new THREE.MeshPhysicalMaterial({ map: createCardTexture(props.userName || 'ADMIN', props.userRole || 'PRIME OPERATOR'), clearcoat: 1, roughness: 0 }));
        face.position.z = 0.081; 
        
        // Back Face (Logo)
        const back = new THREE.Mesh(
            new THREE.PlaneGeometry(rw * 2 - 0.5, rw * 2 - 0.5), // Smaller square for logo
            new THREE.MeshPhysicalMaterial({ map: backLogoTex, transparent: true, clearcoat: 1, roughness: 0.2 })
        );
        back.position.z = -0.081;
        back.rotation.y = Math.PI; // Flip to face backward
        
        cardGroup.add(shell, face, back); 
        scene.add(cardGroup);

        // 📎 METALLIC CLIP (Optimized segments)
        clipMesh = new THREE.Mesh(
            new THREE.TorusGeometry(0.12, 0.03, 8, 16),
            new THREE.MeshPhysicalMaterial({ color: 0x888888, metalness: 1, roughness: 0.2 })
        );
        scene.add(clipMesh);

        // PHYSICS SEGMENTS
        const damping = 4.0;
        fixedBody = world.createRigidBody(RAPIER.RigidBodyDesc.kinematicPositionBased().setTranslation(0, currentAnchorY, 0));
        
        let prev = fixedBody;
        for (let i = 0; i < 4; i++) {
            const body = world.createRigidBody(RAPIER.RigidBodyDesc.dynamic().setTranslation(0, currentAnchorY - (i + 1) * 1.0, 0).setLinearDamping(damping).setAngularDamping(damping));
            world.createCollider(RAPIER.ColliderDesc.ball(0.1), body);
            world.createImpulseJoint(RAPIER.JointData.rope(1.1, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }), prev, body, true);
            joints.push({ body, lerped: new THREE.Vector3(0, currentAnchorY - (i + 1) * 1.0, 0) });
            prev = body;
        }

        cardBody = world.createRigidBody(RAPIER.RigidBodyDesc.dynamic().setTranslation(0, currentAnchorY - 6, 0).setAdditionalMass(6.0).setLinearDamping(damping).setAngularDamping(damping));
        world.createCollider(RAPIER.ColliderDesc.cuboid(rw, rh, 0.08), cardBody);
        world.createImpulseJoint(RAPIER.JointData.spherical({ x: 0, y: 0, z: 0 }, { x: 0, y: rh, z: 0 }), prev, cardBody, true);

        // 🎗️ MESHLINE ROPE
        ropeGeometry = new MeshLineGeometry();
        const ropeMat = new MeshLineMaterial({
            color: new THREE.Color(0x111111),
            lineWidth: 0.1,
            resolution: new THREE.Vector2(w, h),
            sizeAttenuation: 1
        });
        ropeMesh = new THREE.Mesh(ropeGeometry, ropeMat);
        scene.add(ropeMesh);

        loading.value = false;
        animate();
    } catch (err) { console.error(err); }
};

const animate = () => {
    animationFrame = requestAnimationFrame(animate);
    if (!world) return;

    if (isDropping) {
        currentAnchorY = THREE.MathUtils.lerp(currentAnchorY, targetY, 0.05);
        fixedBody.setNextKinematicTranslation({ x: 0, y: currentAnchorY, z: 0 });
        if (Math.abs(currentAnchorY - targetY) < 0.01) isDropping = false;
    } else if (isPulled.value) {
        pullSpeed += pullAccel;
        currentAnchorY += pullSpeed * 0.2;
        fixedBody.setNextKinematicTranslation({ x: 0, y: currentAnchorY, z: 0 });
    }

    world.step();

    // Sync Graphics
    const t = cardBody.translation(); const r = cardBody.rotation();
    cardGroup.position.set(t.x, t.y, t.z); cardGroup.quaternion.set(r.x, r.y, r.z, r.w);

    // Sync Clip Position (Top of card)
    const cardTop = new THREE.Vector3(0, 1.7, 0).applyQuaternion(cardGroup.quaternion).add(cardGroup.position);
    clipMesh.position.copy(cardTop);
    clipMesh.quaternion.copy(cardGroup.quaternion);
    clipMesh.rotateX(Math.PI / 2);

    // Update MeshLine
    const pts = [new THREE.Vector3().copy(fixedBody.translation() as any)];
    joints.forEach(j => {
        const tr = j.body.translation();
        j.lerped.lerp(new THREE.Vector3(tr.x, tr.y, tr.z), 0.15);
        pts.push(j.lerped);
    });
    // Finish rope at the clip instead of the raw card top
    pts.push(new THREE.Vector3().copy(clipMesh.position));

    const curve = new THREE.CatmullRomCurve3(pts);
    ropeGeometry.setPoints(curve.getPoints(20).flatMap(p => [p.x, p.y, p.z]));
    
    renderer.render(scene, camera);
};

onMounted(() => { nextTick(() => setTimeout(init, 50)); });
onUnmounted(() => { 
    cancelAnimationFrame(animationFrame); 
    renderer?.dispose(); 
    scene?.clear(); 
    document.body.style.cursor = 'default';
});
</script>

<style scoped>
.lanyard-container {
  position: fixed; inset: 0; width: 100vw; height: 100vh;
  z-index: 10000; pointer-events: auto;
  animation: lanyard-entry 2.5s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
@keyframes lanyard-entry {
  0% { opacity: 0; filter: blur(30px) brightness(0.5); transform: scale(1.1); }
  100% { opacity: 1; filter: blur(0) brightness(1); transform: scale(1); }
}
canvas { width: 100%; height: 100%; }
.auth-message {
  position: absolute; bottom: 8%; left: 50%; transform: translateX(-50%); text-align: center; pointer-events: none;
}
.glow-text {
  font-family: var(--font-headline); font-size: 2.8rem; font-weight: 900; color: #fff;
  text-shadow: 0 0 50px rgba(255, 140, 0, 0.6); letter-spacing: 0.35em; margin-bottom: 8px;
}
.active-prompt {
  font-family: 'JetBrains Mono', monospace; font-size: 0.85rem; color: #fff; letter-spacing: 0.5em;
  animation: pulse-glow 2s infinite ease-in-out; font-weight: 700;
}
@keyframes pulse-glow {
  0%, 100% { opacity: 0.5; transform: scale(0.98); color: var(--color-primary); }
  50% { opacity: 1; transform: scale(1.02); color: #fff; text-shadow: 0 0 15px var(--color-primary); }
}
</style>
