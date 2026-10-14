import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import './style.css';

const SOURCE_SHA='60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39';
const el=(id)=>document.getElementById(id);
const canvas=el('view');
const lab=window.__diceLab={
  renderer:'Three.js r184 WebGL2',state:'initializing',modelLoaded:false,
  exactOriginal:false,modelTriangles:0,stoneTriangles:0,goldTriangles:0,goldMeshes:0,
  drawTriangles:0,drawCalls:0,renderedFrames:0,fps:0,sourceSha:null,error:null,
  camera:'overhead',demo:true
};
function status(value){lab.state=value;el('state').textContent=value}
function failure(error){console.error(error);lab.error=String(error?.message||error);el('errors').textContent=lab.error;status('Ошибка, см. диагностику');}
const host=el('stage');
let renderer;
try{
  const ctx=canvas.getContext('webgl2',{antialias:true,preserveDrawingBuffer:true,powerPreference:'high-performance',alpha:false});
  if(!ctx)throw new Error('WebGL2 недоступен на этом устройстве');
  renderer=new THREE.WebGLRenderer({canvas,context:ctx,antialias:true,preserveDrawingBuffer:true,powerPreference:'high-performance'});
  renderer.outputColorSpace=THREE.SRGBColorSpace;
  renderer.toneMapping=THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure=.95;
  renderer.setPixelRatio(Math.min(window.devicePixelRatio||1,2));
  lab.glVendor=ctx.getParameter(ctx.VENDOR);
  lab.glVersion=ctx.getParameter(ctx.VERSION);
}catch(error){failure(error)}
const scene=new THREE.Scene();
scene.background=new THREE.Color(0x0b0f0d);
const camera=new THREE.OrthographicCamera(-1.6,1.6,1.6,-1.6,.05,100);
function setCamera(mode){
  lab.camera=mode;
  camera.position.set(mode==='overhead'?0:3.4,mode==='overhead'?4.8:4.4,mode==='overhead'?.001:4.3);
  camera.up.set(0,0,-1);
  camera.lookAt(0,0,0);
  camera.updateProjectionMatrix();
}
setCamera('overhead');
let ambient=null;
let model=null;
let turntable=false;
const startClock=performance.now();
const durations=[];
const frame=(now)=>{
  if(!renderer)return;
  const targetW=host.clientWidth, targetH=host.clientHeight;
  const px=Math.max(1,Math.floor(targetW*Math.min(window.devicePixelRatio||1,2)));
  const py=Math.max(1,Math.floor(targetH*Math.min(window.devicePixelRatio||1,2)));
  if(canvas.width!==px||canvas.height!==py){
    renderer.setSize(targetW,targetH,false);
    const aspect=targetW/targetH;
    const half=1.5;
    camera.left=-half*aspect;camera.right=half*aspect;
    camera.top=half;camera.bottom=-half;
    camera.updateProjectionMatrix();
  }
  if(turntable&&model)model.rotation.y+=.0033;
  renderer.render(scene,camera);
  lab.renderedFrames++;
  lab.drawTriangles=renderer.info.render.triangles;
  lab.drawCalls=renderer.info.render.calls;
  if(lab.renderedFrames>5){
    const dt=now-(lab.previousTs||now);
    if(dt>0&&dt<2000)durations.push(dt);
    if(durations.length>90)durations.shift();
    const mean=durations.reduce((a,b)=>a+b,0)/Math.max(1,durations.length);
    lab.fps=1000/Math.max(1,mean);
  }
  lab.previousTs=now;
  if(lab.renderedFrames%15===0){
    el('fps').textContent='FPS: '+lab.fps.toFixed(1);
    el('gpu-tris').textContent=lab.drawTriangles.toLocaleString('ru-RU');
    el('calls').textContent=lab.drawCalls.toLocaleString('ru-RU');
  }
};
if(renderer){
  const pmrem=new THREE.PMREMGenerator(renderer);
  ambient=pmrem.fromScene(new RoomEnvironment(),.06);
  scene.environment=ambient.texture;
  renderer.setAnimationLoop(frame);
  status('WebGL2 работает · Three.js r184');
  const demo=new THREE.Mesh(
    new THREE.IcosahedronGeometry(.98,1),
    new THREE.MeshPhysicalMaterial({color:0x171d1d,metalness:0,roughness:.16,clearcoat:.32,clearcoatRoughness:.12,flatShading:true})
  );
  demo.name='SYNTHETIC_LOW_POLY_PLACEHOLDER_NOT_OWNER_SOURCE';
  model=demo;
  scene.add(demo);
  lab.demo=true;
}
const loader=new GLTFLoader();
async function loadGLB(file){
  if(!renderer)throw new Error('WebGL2 context not initialized');
  if(!file||(!file.name.toLowerCase().endsWith('.glb')&&file.type!=='model/gltf-binary'))throw new Error('Нужен файл .glb (не картинка)');
  status('Читаю локальный GLB…');
  const bytes=await file.arrayBuffer();
  if(bytes.byteLength<20||new DataView(bytes).getUint32(0,true)!==0x46546c67)throw new Error('Не GLB glTF 2.0');
  const hash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))).map(n=>n.toString(16).padStart(2,'0')).join('');
  lab.sourceSha=hash;
  lab.exactOriginal=hash===SOURCE_SHA;
  status('Загружаю сетку и PBR-карты…');
  const gltf=await loader.parseAsync(bytes,'');
  const root=gltf.scene;
  let triangles=0,stone=0,gold=0,goldMeshes=0,materialNames=new Set(),realNormalTextures=0;
  root.traverse(obj=>{
    if(!obj.isMesh)return;
    const geo=obj.geometry;
    const count=geo.index?.count??geo.attributes.position?.count??0;
    if(count%3)throw new Error('Меш содержит некорректное количество вершин');
    const tri=count/3;
    triangles+=tri;
    if(obj.name.startsWith('D20_Engraved'))stone+=tri;
    if(obj.name.startsWith('Gold_')){gold+=tri;goldMeshes++}
    for(const mat of (Array.isArray(obj.material)?obj.material:[obj.material])){
      if(mat?.name)materialNames.add(mat.name);
      if(mat?.normalMap)realNormalTextures++;
    }
  });
  lab.modelTriangles=triangles;lab.stoneTriangles=stone;lab.goldTriangles=gold;lab.goldMeshes=goldMeshes;
  lab.modelLoaded=true;lab.demo=false;
  const verified=lab.exactOriginal&&triangles===500000&&stone===220000&&gold===280000&&goldMeshes===20;
  lab.verifiedPremium=verified;
  if(model){scene.remove(model);model.traverse?.(o=>{if(o===model&&o.geometry?.type?.includes('Icosahedron')){o.geometry.dispose();o.material?.dispose?.()}})}
  model=root;
  if(verified){
    const basis=new THREE.Matrix4().makeBasis(
      new THREE.Vector3(-.99980195,-.00372885,.01954887),
      new THREE.Vector3(-.00363344,-.93157876,-.36352142),
      new THREE.Vector3(.01956683,-.36352045,.93138071)
    );
    model.quaternion.setFromRotationMatrix(basis);
    model.scale.setScalar(.895);
  }else{
    const bounds=new THREE.Box3().setFromObject(model);
    const size=bounds.getSize(new THREE.Vector3()).length();
    if(size>0)model.scale.multiplyScalar(1.8/size);
  }
  scene.add(model);
  status(verified?'Проверен оригинальный 500k обсидиан':'GLB загружен · НЕ подтверждён исходник');
  el('asset').textContent=verified?'500k original ✓':`${triangles.toLocaleString('ru-RU')} tris (другой GLB)`;
  el('sha').textContent='SHA-256 '+hash+' · '+(verified?'оригинальный приватный PBR':'не совпадает с сохранённым D20');
  el('details').textContent=`Меш: ${triangles.toLocaleString('ru-RU')} треугольников. Камень: ${stone.toLocaleString('ru-RU')}. Золото: ${gold.toLocaleString('ru-RU')}, ${goldMeshes} частей. PBR normalMap: ${realNormalTextures}. Материалы: ${Array.from(materialNames).join(', ')}. В браузерном тесте физика/результат броска не реализованы.`;
  return lab;
}
lab.loadGLB=loadGLB;
el('model-file').addEventListener('change',async(event)=>{
  el('errors').textContent='';
  try{const chosen=event.target.files?.[0];if(chosen)await loadGLB(chosen)}catch(e){failure(e)}
});
el('top').addEventListener('click',()=>setCamera('overhead'));
el('tilt').addEventListener('click',()=>setCamera('tilted'));
el('rotate').addEventListener('click',()=>{turntable=!turntable;el('rotate').textContent=turntable?'Остановить':'Вращать модель'});
el('capture').addEventListener('click',()=>{
  if(!renderer){failure(new Error('Нет GPU-кадра'));return}
  const link=document.createElement('a');
  link.href=canvas.toDataURL('image/png');
  link.download='D20_ThreeJS_WebGL2_actual_frame.png';
  link.click();
});
