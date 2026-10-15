import * as THREE from 'three';
import { ICO_FACES, ICO_VERTICES, FACE_NORMALS, FACE_VALUES, faceForValue,
  measuredFace, cryptoDie } from './rng_first.mjs';

/**
 * Clearly labeled FREE demo model, never confused with user's 500k BlenderKit
 * original. Face assignments match the ORIGINAL mesh's canonical printed map.
 */
export function createDemoNumberedD20(){
  const group=new THREE.Group();
  group.name='SYNTHETIC_NUMBERED_D20_NOT_USER_OBSIDIAN';
  const vertices=[],normals=[];
  const radius=.98;
  for(let i=0;i<ICO_FACES.length;i++){
    const n=FACE_NORMALS[i];
    for(const idx of ICO_FACES[i]){
      const p=ICO_VERTICES[idx];
      vertices.push(...p.map(c=>c*radius));
      normals.push(...n);
    }
  }
  const geo=new THREE.BufferGeometry();
  geo.setAttribute('position',new THREE.Float32BufferAttribute(vertices,3));
  geo.setAttribute('normal',new THREE.Float32BufferAttribute(normals,3));
  group.add(new THREE.Mesh(geo,new THREE.MeshPhysicalMaterial({
    color:0x141819,metalness:0,roughness:.18,clearcoat:.6,clearcoatRoughness:.09,
    flatShading:true,side:THREE.DoubleSide
  })));
  const labelMaterials=[];
  for(let i=0;i<20;i++){
    const canvas=document.createElement('canvas');
    canvas.width=256;canvas.height=256;
    const g=canvas.getContext('2d');
    if(!g)throw new Error('Cannot render demo numbered D20 glyph');
    g.clearRect(0,0,256,256);
    g.textAlign='center';g.textBaseline='middle';
    g.font='bold 152px Georgia, serif';
    g.fillStyle='#dcb668';g.fillText(String(FACE_VALUES[i]),128,139);
    const tex=new THREE.CanvasTexture(canvas);
    tex.colorSpace=THREE.SRGBColorSpace;
    const mat=new THREE.MeshBasicMaterial({
      map:tex,transparent:true,depthWrite:false,side:THREE.DoubleSide,
      polygonOffset:true,polygonOffsetFactor:-1
    });
    labelMaterials.push(mat);
    const center=new THREE.Vector3();
    for(const index of ICO_FACES[i]){
      const v=ICO_VERTICES[index];
      center.add(new THREE.Vector3(...v).multiplyScalar(radius));
    }
    center.divideScalar(3);
    const normal=new THREE.Vector3(...FACE_NORMALS[i]);
    const label=new THREE.Mesh(new THREE.PlaneGeometry(.46,.46),mat);
    label.name='SyntheticGold_'+FACE_VALUES[i];
    label.position.copy(center).addScaledVector(normal,.014);
    label.quaternion.setFromUnitVectors(new THREE.Vector3(0,0,1),normal);
    group.add(label);
  }
  group.userData.disposeDemo=()=>{
    geo.dispose();
    for(const mat of labelMaterials){mat.map?.dispose();mat.dispose();}
  };
  return group;
}
export function quaternionForPrintedFace(value,yawRadians=0){
  const normal=new THREE.Vector3(...FACE_NORMALS[faceForValue(value)]);
  const up=new THREE.Vector3(0,1,0);
  const align=new THREE.Quaternion().setFromUnitVectors(normal,up);
  const yaw=new THREE.Quaternion().setFromAxisAngle(up,yawRadians);
  return yaw.multiply(align).normalize();
}
const clamp=(v,min,max)=>Math.max(min,Math.min(max,v));
const smooth=(v)=>{const x=clamp(v,0,1);return x*x*(3-2*x)};
/**
 * RNG-first: target is supplied by immutable roll plan BEFORE motion.
 * Presentation is scripted cinematic pseudo-physics, NOT a rigid-body solver.
 * The final printed face is independently checked after animation.
 */
export function animateToPrintedFace(group,target,{
  duration=2300,onUpdate=()=>{},animationFrame=requestAnimationFrame,
  now=()=>performance.now(),randomDie=cryptoDie
}={}){
  if(!group?.isObject3D) return Promise.reject(new TypeError('Missing actual Three.js D20'));
  const yaw=(randomDie(360)-1)*Math.PI/180;
  const destination=quaternionForPrintedFace(target,yaw);
  // Start with genuine tumble, then blend smoothly toward PRECOMMITTED target.
  const twistX=(randomDie(4)+2)*Math.PI;
  const twistZ=(randomDie(4)+2)*Math.PI;
  const twistY=(randomDie(3)+2)*Math.PI;
  const from=new THREE.Euler(
    (randomDie(360)-1)*Math.PI/180,
    (randomDie(360)-1)*Math.PI/180,
    (randomDie(360)-1)*Math.PI/180,'XYZ');
  const driftX=(randomDie(200)-100)/260;
  const driftZ=(randomDie(200)-100)/260;
  const switchAt=.69;
  const flightEndEuler=new THREE.Euler(from.x+twistX*switchAt,
      from.y+twistY*switchAt,from.z+twistZ*switchAt,'XYZ');
  const endOfFlight=new THREE.Quaternion().setFromEuler(flightEndEuler);
  const first=now();
  return new Promise((resolve,reject)=>{
    const tick=(clock)=>{
      try{
        const t=clamp((clock-first)/duration,0,1);
        if(t<switchAt){
          group.rotation.set(from.x+twistX*t,from.y+twistY*t,
            from.z+twistZ*t,'XYZ');
        }else{
          group.quaternion.copy(endOfFlight).slerp(destination,
            smooth((t-switchAt)/(1-switchAt)));
        }
        // Simulated bounce and tangential friction. Jolt/physics is NOT used.
        const ballistic=Math.sin(Math.PI*clamp(t/switchAt,0,1));
        const bounce=t>=switchAt?
          .13*Math.abs(Math.sin((t-switchAt)*Math.PI*10))*Math.pow(1-t,2):0;
        group.position.set(driftX*Math.pow(1-t,2),
          .06+.8*Math.max(0,ballistic)+bounce,
          driftZ*Math.pow(1-t,2));
        onUpdate(t);
        if(t<1){animationFrame(tick);return;}
        const measured=measuredFace(group.quaternion);
        if(measured.value!==target||measured.upDot<.99)
          throw new Error('VISIBLE FACE MISMATCH: RNG='+target+' visible='+measured.value);
        resolve({target,visible:measured.value,angleDot:measured.upDot,yaw,
          animation:'RNG-first kinematic animation, not authoritative physics'});
      }catch(e){reject(e)}
    };
    animationFrame(tick);
  });
}
