import * as THREE from 'three';
import rng from './rng.cjs';

const {secureDie}=rng;
const sides=20;
const id=name=>document.getElementById(name);
const viewport=id('viewport');
const scene=new THREE.Scene();
scene.background=new THREE.Color('#13151a');
const camera=new THREE.OrthographicCamera(-3.25,3.25,3.25,-3.25,.01,100);
camera.position.set(0,8,.012);
camera.up.set(0,0,-1);
camera.lookAt(0,0,0);
const renderer=new THREE.WebGLRenderer({antialias:true,alpha:false,powerPreference:'high-performance'});
renderer.setPixelRatio(Math.min(devicePixelRatio||1,2));
renderer.outputColorSpace=THREE.SRGBColorSpace;
renderer.toneMapping=THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure=1.65;
renderer.shadowMap.enabled=true;
renderer.shadowMap.type=THREE.PCFSoftShadowMap;
viewport.prepend(renderer.domElement);
const deskMat=new THREE.MeshStandardMaterial({color:0x24282d,roughness:.97,metalness:0});
const desk=new THREE.Mesh(new THREE.PlaneGeometry(90,90),deskMat);
desk.rotation.x=-Math.PI/2;
desk.position.y=-1.73;
desk.receiveShadow=true;
scene.add(desk);
scene.add(new THREE.HemisphereLight(0xe4eaf9,0x303034,1.9));
const key=new THREE.DirectionalLight(0xf2f7ff,4.0);
key.position.set(-2.6,7,3.1);
key.castShadow=true;
key.shadow.mapSize.set(1024,1024);
key.shadow.camera.left=-4;key.shadow.camera.right=4;key.shadow.camera.top=4;key.shadow.camera.bottom=-4;
key.shadow.camera.near=1;key.shadow.camera.far=20;
key.shadow.bias=-.0002;
scene.add(key);
const warm=new THREE.DirectionalLight(0xffc78b,2.1);
warm.position.set(3.7,5,-1.8);scene.add(warm);
const rim=new THREE.DirectionalLight(0x9dbddc,2.0);
rim.position.set(1.0,3.0,4.2);scene.add(rim);

const die=new THREE.Group();
scene.add(die);
const stone=new THREE.MeshPhysicalMaterial({
  color:0x080b11,roughness:.15,metalness:0,
  clearcoat:1,clearcoatRoughness:.12,side:THREE.FrontSide,
  flatShading:true
});
const gold=new THREE.MeshStandardMaterial({color:0xe9b96e,metalness:.68,roughness:.3,
  transparent:true,alphaTest:.12,side:THREE.DoubleSide,depthWrite:false});
const solid=new THREE.Mesh(new THREE.IcosahedronGeometry(1.47,0),stone);
solid.castShadow=true;
solid.receiveShadow=true;
die.add(solid);
const edges=new THREE.LineSegments(
  new THREE.EdgesGeometry(solid.geometry,1),
  new THREE.LineBasicMaterial({color:0x756d60,transparent:true,opacity:.53}));
die.add(edges);

const vertex=solid.geometry.getAttribute('position');
const normals=[];
const meshes=[];
for(let face=0;face<vertex.count/3;face++){
  const a=new THREE.Vector3().fromBufferAttribute(vertex,face*3);
  const b=new THREE.Vector3().fromBufferAttribute(vertex,face*3+1);
  const c=new THREE.Vector3().fromBufferAttribute(vertex,face*3+2);
  const center=a.clone().add(b).add(c).divideScalar(3);
  const normal=b.clone().sub(a).cross(c.clone().sub(a)).normalize();
  if(normal.dot(center)<0)normal.negate();
  const index=face+1;
  normals.push(normal);
  const canvas=document.createElement('canvas');
  canvas.width=canvas.height=512;
  const ctx=canvas.getContext('2d');
  ctx.clearRect(0,0,512,512);
  ctx.font='bold 300px Georgia, serif';
  ctx.textAlign='center';ctx.textBaseline='middle';
  ctx.shadowColor='#000';ctx.shadowBlur=6;
  ctx.lineWidth=14;ctx.strokeStyle='#1d140c';ctx.strokeText(String(index),256,267);
  ctx.shadowBlur=0;ctx.fillStyle='#dfad5e';ctx.fillText(String(index),256,267);
  const texture=new THREE.CanvasTexture(canvas);
  texture.colorSpace=THREE.SRGBColorSpace;
  texture.anisotropy=Math.min(8,renderer.capabilities.getMaxAnisotropy());
  const material=gold.clone();
  material.map=texture;
  material.color.setRGB(1,1,1);
  const symbol=new THREE.Mesh(new THREE.PlaneGeometry(.87,.87),material);
  const orientation=new THREE.Quaternion().setFromUnitVectors(
    new THREE.Vector3(0,0,1),normal);
  symbol.quaternion.copy(orientation);
  symbol.position.copy(center).addScaledVector(normal,.021);
  symbol.renderOrder=1;
  die.add(symbol);
  meshes.push(symbol);
}
if(normals.length!==20)throw Error('Actual D20 geometry must contain 20 flat triangle faces');
die.position.y=0.04;
const UP=new THREE.Vector3(0,1,0);
let rolling=false,lastRoll=null,rolls=0;
const qa={renderer:'Three.js WebGL',usesJolt:false,usesGodot:false,
  faces:normals.length,chosenBeforeAnimation:false,
  engine:'three',get lastRoll(){return lastRoll},get rolling(){return rolling},
  get rolls(){return rolls},get WebGL(){return renderer.capabilities.isWebGL2}};
globalThis.__DICE_QA__=qa;
const easing=t=>1-Math.pow(1-t,4);
const tmpSpin=new THREE.Quaternion(),tmpAligned=new THREE.Quaternion();
function runRoll({duration=1900,chosen}={}){
  if(rolling)return Promise.reject(new Error('Roll already active'));
  const selected=chosen===undefined?secureDie(sides):chosen;
  if(!Number.isInteger(selected)||selected<1||selected>20)
    throw new RangeError('Invalid D20 result');
  // Crucial: selected result is frozen BEFORE first animation frame.
  rolling=true;
  id('roll').disabled=true;
  id('result').textContent='D20 / …';
  id('status').textContent='RNG уже выбрал результат. 3D-анимация подчиняется числу.';
  const target=new THREE.Quaternion().setFromUnitVectors(normals[selected-1],UP);
  const yaw=new THREE.Quaternion().setFromAxisAngle(UP,((rolls*137.508)%360)*Math.PI/180);
  target.premultiply(yaw);
  const initial=die.quaternion.clone();
  const rotationAxis=new THREE.Vector3(.72,.4,.65).normalize();
  const start=performance.now();
  lastRoll={selected,committedAt:start,finished:false,topFace:null,topDot:null};
  qa.chosenBeforeAnimation=true;
  return new Promise(resolve=>{
    function frame(now){
      const t=Math.min(1,(now-start)/Math.max(1,duration));
      const ease=easing(t);
      tmpAligned.copy(initial).slerp(target,ease);
      const wobble=3*2*Math.PI*(1-t)*(1-t);
      tmpSpin.setFromAxisAngle(rotationAxis,wobble);
      die.quaternion.copy(tmpSpin).multiply(tmpAligned);
      const hop=Math.sin(Math.PI*t)*.39*(1-t);
      die.position.y=.04+hop;
      if(t<1){requestAnimationFrame(frame);return;}
      // Final quaternion is already target because wobble -> 0 and slerp -> 1.
      // No final quaternion snap. Check actual 3D local facet normal.
      die.quaternion.copy(target);
      die.position.y=.04;
      let faceIndex=0,best=-Infinity;
      normals.forEach((n,i)=>{
        const y=n.clone().applyQuaternion(die.quaternion).dot(UP);
        if(y>best){best=y;faceIndex=i+1}
      });
      lastRoll.finished=true;
      lastRoll.topFace=faceIndex;
      lastRoll.topDot=best;
      lastRoll.matches=faceIndex===selected&&best>.9999;
      rolling=false;rolls++;
      id('roll').disabled=false;
      id('result').textContent='D20 / '+selected;
      id('status').textContent=lastRoll.matches?
        'RNG '+selected+' · верхняя 3D-грань '+faceIndex+' · совпало':
        'ОШИБКА: верхняя грань не совпала с RNG!';
      if(!lastRoll.matches)console.error('D20 rng-face mismatch',lastRoll);
      resolve({...lastRoll});
    }
    requestAnimationFrame(frame);
  });
}
globalThis.__DICE_QA__.rollForTest=(result,duration=3)=>runRoll({duration,chosen:result});
globalThis.__DICE_QA__.roll=()=>runRoll();
id('roll').addEventListener('click',()=>{runRoll().catch(e=>{
  id('status').textContent=e.message;rolling=false;id('roll').disabled=false})});
id('sides').value='20';id('sides').disabled=true;
id('sides').setAttribute('title','Текущий 3D-эксперимент проверяет D20; остальные геометрии позже.');
const clock=new THREE.Clock();
let prior=performance.now(),draws=0;
function render(now){
  draws++;
  if(now-prior>1000){id('fps').textContent='WEBGL · '+Math.round(draws*1000/(now-prior))+' FPS';
    draws=0;prior=now;}
  renderer.render(scene,camera);
  requestAnimationFrame(render);
}
function resize(){
 const w=viewport.clientWidth,h=viewport.clientHeight;
 camera.left=-3.25*w/h;camera.right=3.25*w/h;
 camera.top=3.25;camera.bottom=-3.25;
 camera.updateProjectionMatrix();
 renderer.setSize(w,h,false);
}
new ResizeObserver(resize).observe(viewport);
resize();
requestAnimationFrame(render);
qa.ready=true;
id('status').textContent='Реальный WebGL D20 готов. RNG определяет число первым.';
