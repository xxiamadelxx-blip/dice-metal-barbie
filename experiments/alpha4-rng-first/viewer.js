'use strict';
/* Independent native WebGL2 GLB viewer. No Godot, Jolt, runtime CDN, or file upload. */
(() => {
const el=id=>document.getElementById(id), canvas=el('canvas');
const gl=canvas.getContext('webgl2',{antialias:true,alpha:false,depth:true,preserveDrawingBuffer:true});
const state={ready:false,busy:false,selected:0,visibleFace:null,drawCount:0,triangles:0,parts:0,frames:0,assetName:null,meshInfo:[],error:null,lastDurationMs:0};
const unit=v=>{const l=Math.hypot(...v);return v.map(x=>x/l)};
const dot=(a,b)=>a.reduce((s,v,i)=>s+v*b[i],0);
const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const qmul=(a,b)=>[a[3]*b[0]+a[0]*b[3]+a[1]*b[2]-a[2]*b[1],a[3]*b[1]-a[0]*b[2]+a[1]*b[3]+a[2]*b[0],a[3]*b[2]+a[0]*b[1]-a[1]*b[0]+a[2]*b[3],a[3]*b[3]-a[0]*b[0]-a[1]*b[1]-a[2]*b[2]];
const qnorm=q=>{const d=Math.hypot(...q);return q.map(x=>x/d)};
const qaxis=(v,t)=>[...unit(v).map(x=>x*Math.sin(t/2)),Math.cos(t/2)];
const qfrom=(from,to)=>{const d=dot(from,to);if(d<-.999999){let v=cross(from,[1,0,0]);if(Math.hypot(...v)<.001)v=cross(from,[0,1,0]);return qaxis(v,Math.PI)}return qnorm([...cross(from,to),1+d])};
const qrot=(q,v)=>{const u=q.slice(0,3),t=cross(u,v).map(x=>x*2),a=cross(u,t);return v.map((x,i)=>x+q[3]*t[i]+a[i])};
const qslerp=(a,b,t)=>{let d=dot(a,b);if(d<0){b=b.map(x=>-x);d=-d}if(d>.9995)return qnorm(a.map((x,i)=>x+(b[i]-x)*t));const theta=Math.acos(Math.min(1,d)),s=Math.sin(theta);return a.map((x,i)=>(x*Math.sin((1-t)*theta)+b[i]*Math.sin(t*theta))/s)};
function qmat(q,translation=[0,0,0]){const [x,y,z,w]=q;return new Float32Array([1-2*(y*y+z*z),2*(x*y+z*w),2*(x*z-y*w),0,2*(x*y-z*w),1-2*(x*x+z*z),2*(y*z+x*w),0,2*(x*z+y*w),2*(y*z-x*w),1-2*(x*x+y*y),0,...translation,1])}
function secureRoll(n=20,cryptoAPI=globalThis.crypto){if(!cryptoAPI?.getRandomValues)throw Error('Secure RNG unavailable');const a=new Uint32Array(1),lim=Math.floor(0x100000000/n)*n;do{cryptoAPI.getRandomValues(a)}while(a[0]>=lim);return a[0]%n+1}
const matNode=n=>qmat(n.rotation??[0,0,0,1],n.translation??[0,0,0]);
const htmlStatus=(text,isError=false)=>{el('status').textContent=text;el('status').style.color=isError?'#f0a1a1':'#c9b9a0'};
if(!gl){htmlStatus('WebGL2 недоступен в данном браузере',true);return}
const vertex=`#version 300 es
precision highp float;
in vec3 POSITION;in vec3 NORMAL;in vec2 TEXCOORD_0;
uniform mat4 uDie;uniform mat4 uNode;uniform mat4 uProjection;
out vec3 vNormal;out vec3 vPosition;out vec2 vUV;
void main(){mat4 model=uDie*uNode;vec4 p=model*vec4(POSITION,1.0);vPosition=p.xyz;vNormal=mat3(model)*NORMAL;vUV=TEXCOORD_0;gl_Position=uProjection*p;}`;
const fragment=`#version 300 es
precision highp float;
in vec3 vNormal;in vec3 vPosition;in vec2 vUV;
uniform sampler2D uAlbedo;uniform sampler2D uNormal;
uniform int uType;uniform int uHasAlbedo;uniform int uHasNormal;
uniform vec3 uBaseFactor;uniform float uNormalScale;uniform float uRoughness;uniform float uMetalness;
out vec4 o;
float disk(vec3 reflection,vec3 direction,float angularRadius,float feather){float cosAngle=dot(reflection,normalize(direction));return smoothstep(cos(angularRadius+feather),cos(angularRadius-feather),cosAngle);}
vec3 linearToSRGB(vec3 c){return pow(max(c,vec3(0.)),vec3(1.0/2.2));}
void main(){
 vec3 norm=normalize(vNormal);vec3 eye=normalize(-vPosition);
 if(!gl_FrontFacing)norm=-norm;
 if(uHasNormal==1){
   vec3 dpos1=dFdx(vPosition),dpos2=dFdy(vPosition);
   vec2 duv1=dFdx(vUV),duv2=dFdy(vUV);
   vec3 tangent=normalize(dpos1*duv2.y-dpos2*duv1.y);
   vec3 bitangent=normalize(-dpos1*duv2.x+dpos2*duv1.x);
   vec3 nm=texture(uNormal,vUV).rgb*2.0-1.0;
   nm.xy*=uNormalScale;
   norm=normalize(mat3(tangent,bitangent,norm)*nm);
 }
 vec3 reflection=reflect(-eye,norm);
 vec3 linearBase=uBaseFactor;
 if(uHasAlbedo==1){vec3 albedo=texture(uAlbedo,vUV).rgb;linearBase*=pow(albedo,vec3(2.2));}
 float NoV=max(dot(norm,eye),0.0);
 float f=pow(1.0-NoV,5.0);
 vec3 f0=mix(vec3(0.04),linearBase,clamp(uMetalness,0.,1.));
 vec3 fresnel=f0+(vec3(1.0)-f0)*f;
 float direct=max(dot(norm,normalize(vec3(-.35,.60,.73))),0.0);
 vec3 diffuse=linearBase*(0.055+direct*0.16)*(1.0-uMetalness);
 float soft1=disk(reflection,vec3(.18,.30,.94),.19,.13);
 float soft2=disk(reflection,vec3(-.84,.20,.52),.23,.20);
 float soft3=disk(reflection,vec3(.78,-.48,.41),.15,.17);
 float shine=mix(1.2,.45,clamp((uRoughness-.06)*2.,0.,1.));
 vec3 studio=(vec3(.65,.72,.81)*soft1*2.7+vec3(.77,.66,.49)*soft2*.65+vec3(.44,.59,.81)*soft3*.37)*shine;
 vec3 specular=studio*fresnel;
 if(uType==2){diffuse+=linearBase*(.25+.63*direct);specular+=vec3(.95,.67,.32)*pow(max(dot(reflect(-normalize(vec3(-.35,.60,.73)),norm),eye),0.0),mix(100.0,14.0,uRoughness))*1.4;}
 vec3 color=diffuse+specular+vec3(.002,.003,.004);
 o=vec4(linearToSRGB(color),1.0);
}`;
function compile(type,code){const sh=gl.createShader(type);gl.shaderSource(sh,code);gl.compileShader(sh);if(!gl.getShaderParameter(sh,gl.COMPILE_STATUS))throw Error('GLSL: '+gl.getShaderInfoLog(sh));return sh}
const program=gl.createProgram();gl.attachShader(program,compile(gl.VERTEX_SHADER,vertex));gl.attachShader(program,compile(gl.FRAGMENT_SHADER,fragment));gl.linkProgram(program);if(!gl.getProgramParameter(program,gl.LINK_STATUS))throw Error('Link: '+gl.getProgramInfoLog(program));gl.useProgram(program);
const uniform={};for(const n of ['uDie','uNode','uProjection','uType','uHasAlbedo','uHasNormal','uBaseFactor','uNormalScale','uRoughness','uMetalness','uAlbedo','uNormal'])uniform[n]=gl.getUniformLocation(program,n);
const locations={};for(const name of ['POSITION','NORMAL','TEXCOORD_0'])locations[name]=gl.getAttribLocation(program,name);
const projection=new Float32Array([1.55,0,0,0,0,1.55,0,0,0,0,-1.001,-1,0,0,-.1001,0]);gl.uniformMatrix4fv(uniform.uProjection,false,projection);
gl.uniform1i(uniform.uAlbedo,0);gl.uniform1i(uniform.uNormal,1);
gl.enable(gl.DEPTH_TEST);gl.depthFunc(gl.LEQUAL);gl.disable(gl.CULL_FACE);gl.clearColor(.042,.043,.06,1);
const white=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,white);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,1,1,0,gl.RGBA,gl.UNSIGNED_BYTE,new Uint8Array([255,255,255,255]));
const flatNormal=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,flatNormal);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,1,1,0,gl.RGBA,gl.UNSIGNED_BYTE,new Uint8Array([128,128,255,255]));
let pieces=[],goldFaces=new Map(),glyphUpVectors=new Map(),buffers=[],textures=[],current=[0,0,0,1],roll=null,lastTime=0,totalTris=0;
function accessorProps(a){const typeCount={SCALAR:1,VEC2:2,VEC3:3,VEC4:4,MAT4:16}[a.type];if(!typeCount)throw Error('Accessor type unsupported: '+a.type);return {size:typeCount,type:a.componentType,count:a.count,offset:a.byteOffset||0}}
/** Offline SHA-256 fallback for Android opaque file:// origins without SubtleCrypto. */
function sha256Fallback(arrayBuffer){
 const raw=new Uint8Array(arrayBuffer), size=raw.length, padded=Math.ceil((size+9)/64)*64;
 const message=new Uint8Array(padded);message.set(raw);message[size]=0x80;
 const bits=size*8, dv=new DataView(message.buffer);
 dv.setUint32(padded-8,Math.floor(bits/4294967296),false);dv.setUint32(padded-4,bits>>>0,false);
 const h=new Uint32Array([0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19]);
 const k=new Uint32Array([0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2]);
 const r=(x,n)=>(x>>>n)|(x<<(32-n)),w=new Uint32Array(64);
 for(let start=0;start<padded;start+=64){
  for(let j=0;j<16;j++)w[j]=dv.getUint32(start+j*4,false);
  for(let j=16;j<64;j++){const a=w[j-15],b=w[j-2];w[j]=(w[j-16]+(r(a,7)^r(a,18)^(a>>>3))+w[j-7]+(r(b,17)^r(b,19)^(b>>>10)))>>>0}
  let [a,b,c,d,e,f,g,z]=h;
  for(let j=0;j<64;j++){
   const s1=r(e,6)^r(e,11)^r(e,25),choose=(e&f)^(~e&g);
   const t1=(z+s1+choose+k[j]+w[j])>>>0;
   const s0=r(a,2)^r(a,13)^r(a,22),major=(a&b)^(a&c)^(b&c);
   const t2=(s0+major)>>>0;
   z=g;g=f;f=e;e=(d+t1)>>>0;d=c;c=b;b=a;a=(t1+t2)>>>0;
  }
  for(const [i,v] of [a,b,c,d,e,f,g,z].entries())h[i]=(h[i]+v)>>>0;
 }
 return Array.from(h,v=>v.toString(16).padStart(8,'0')).join('');
}
async function sha256Hex(buffer){
 if(globalThis.crypto?.subtle?.digest){
  const digest=await globalThis.crypto.subtle.digest('SHA-256',buffer);
  return Array.from(new Uint8Array(digest),v=>v.toString(16).padStart(2,'0')).join('');
 }
 return sha256Fallback(buffer);
}
async function loadGLB(arrayBuffer,name='D20 source'){
  // Fail closed BEFORE allocating GPU buffers or accepting a model as original.
  // Synthetic benchmark fixture is explicitly test-only and cannot masquerade as original.
  const syntheticFixture=name==='PUBLIC_SYNTHETIC_QA';
  if(!syntheticFixture){
    const actual=await sha256Hex(arrayBuffer);
    const expected='60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39';
    if(actual!==expected)throw Error('GLB SHA-256 mismatch: selected file is NOT the approved original D20');
    state.assetSha256=actual;
  }else{state.assetSha256='SYNTHETIC_QA_NOT_ORIGINAL';}
  const view=new DataView(arrayBuffer);if(view.getUint32(0,true)!==0x46546c67||view.getUint32(4,true)!==2)throw Error('Only glTF 2.0 GLB supported');
  let idx=12,json=null,bin=null;while(idx+8<=arrayBuffer.byteLength){const len=view.getUint32(idx,true),kind=view.getUint32(idx+4,true);idx+=8;if(kind===0x4e4f534a)json=JSON.parse(new TextDecoder().decode(arrayBuffer.slice(idx,idx+len)));if(kind===0x004e4942)bin=new Uint8Array(arrayBuffer,idx,len);idx+=len}
  if(!json||!bin||!json.accessors||!json.bufferViews)throw Error('GLB missing JSON/BIN');
  if(json.extensionsRequired?.length)throw Error('Unsupported glTF required extension '+json.extensionsRequired.join(','));
  const viewBytes=bv=>new Uint8Array(arrayBuffer,bin.byteOffset+(bv.byteOffset??0),bv.byteLength);
  const gpuBuffers=json.bufferViews.map(bv=>{const b=gl.createBuffer();const target=bv.target||gl.ARRAY_BUFFER;gl.bindBuffer(target,b);gl.bufferData(target,viewBytes(bv),gl.STATIC_DRAW);return {buffer:b,target}});
  const images=await Promise.all((json.images||[]).map(async image=>{let data,mime=image.mimeType||'image/png';if(image.bufferView!==undefined)data=viewBytes(json.bufferViews[image.bufferView]);else throw Error('External image files not supported');const blob=new Blob([data],{type:mime});return createImageBitmap(blob,{imageOrientation:'flipY',premultiplyAlpha:'none'})}));
  const gpuTextures=(json.textures||[]).map((t)=>{const sampler=json.samplers?.[t.sampler]||{},bmp=images[t.source];if(!bmp)throw Error('Missing texture source');const tex=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,tex);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,sampler.wrapS??gl.REPEAT);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,sampler.wrapT??gl.REPEAT);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR_MIPMAP_LINEAR);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,bmp);gl.generateMipmap(gl.TEXTURE_2D);return tex});
  const result=[],gold=new Map(),glyphUp=new Map();let tris=0;
  for(const n of (json.nodes||[])){
   if(n.mesh===undefined)continue;const mesh=json.meshes[n.mesh],nodeMatrix=matNode(n),nodeRot=n.rotation||[0,0,0,1];
   const goldMatch=/^Gold_(\d{1,2})$/.exec(n.name||'');if(goldMatch){const face=Number(goldMatch[1]);if(gold.has(face))throw Error('Duplicate gold number '+face);const cent=n.translation||[0,0,0];gold.set(face,unit(cent));glyphUp.set(face,qrot(nodeRot,syntheticFixture?[0,1,0]:[0,0,1]));}
   for(const p of mesh.primitives){if((p.mode??4)!==4)throw Error('Triangle mesh required');if(p.indices===undefined)throw Error('Indexed triangles required');
    const vao=gl.createVertexArray();gl.bindVertexArray(vao);for(const attr of ['POSITION','NORMAL','TEXCOORD_0']){
      let aId=p.attributes[attr],loc=locations[attr];if(aId===undefined){gl.disableVertexAttribArray(loc);gl.vertexAttrib3f(loc,0,0,attr==='NORMAL'?1:0);continue}
      const a=json.accessors[aId],bv=json.bufferViews[a.bufferView],info=accessorProps(a);if(a.sparse)throw Error('Sparse accessor not supported');
      if(info.type!==gl.FLOAT)throw Error('Float attributes required');gl.bindBuffer(gl.ARRAY_BUFFER,gpuBuffers[a.bufferView].buffer);gl.enableVertexAttribArray(loc);gl.vertexAttribPointer(loc,info.size,info.type,!!a.normalized,bv.byteStride||0,info.offset);
    }
    const ind=json.accessors[p.indices];if(![gl.UNSIGNED_SHORT,gl.UNSIGNED_INT].includes(ind.componentType))throw Error('Indices must be U16/U32');
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER,gpuBuffers[ind.bufferView].buffer);const mat=json.materials?.[p.material]||{},pbr=mat.pbrMetallicRoughness||{};
    result.push({vao,count:ind.count,offset:ind.byteOffset||0,indType:ind.componentType,node:nodeMatrix,nodeName:n.name||mesh.name,matType:goldMatch?2:0,base:pbr.baseColorTexture?.index,normal:mat.normalTexture?.index,baseFactor:pbr.baseColorFactor||[1,1,1,1],normalScale:mat.normalTexture?.scale??1,rough:pbr.roughnessFactor??1,metal:pbr.metallicFactor??1});tris+=ind.count/3;
   }
  }
  if(gold.size!==20||Array.from({length:20},(_,i)=>i+1).some(i=>!gold.has(i)))throw Error('Expected 20 original numbered gold meshes, found '+gold.size);
  if(!result.length)throw Error('No drawable meshes');
  // Keep local-only source material private. No network transfer; binary stays in browser memory.
  pieces=result;goldFaces=gold;glyphUpVectors=glyphUp;buffers=gpuBuffers;textures=gpuTextures;totalTris=tris;
  state.syntheticFixture=syntheticFixture;
  state.ready=true;state.triangles=tris;state.parts=result.length;state.assetName=name;state.meshInfo=result.map(x=>x.nodeName);el('roll').disabled=false;
  el('metrics').textContent=tris.toLocaleString('ru')+' треугольников · '+result.length+' поверхностей · '+gold.size+' цифр';
  htmlStatus(name==='PUBLIC_SYNTHETIC_QA'
    ? 'СИНТЕТИЧЕСКИЙ QA D20: только тест Android WebGL2, НЕ исходный обсидиан.'
    : 'Локальный GLB загружен. RNG выберет грань до начала анимации.');return {triangles:tris,parts:result.length,faces:gold.size}
 }
 function uprightTarget(face){
  const normal=goldFaces.get(face),letterUp=glyphUpVectors.get(face);
  if(!normal||!letterUp)throw Error('Original numbered face up-vector not available '+face);
  const align=qfrom(normal,[0,0,1]);
  const forward=qrot(align,letterUp);
  if(Math.hypot(forward[0],forward[1])<0.01)throw Error('Degenerate gold lettering orientation '+face);
  const twist=Math.atan2(forward[0],forward[1]);
  return qnorm(qmul(qaxis([0,0,1],twist),align));
 }
 function setTarget(face){if(!state.ready||!goldFaces.has(face))throw Error('No loaded GLB or invalid face '+face);current=uprightTarget(face);state.selected=face;state.visibleFace=face;el('result').textContent=face}
 function chooseFace(face=null){if(!state.ready||state.busy)return false;const result=face===null?secureRoll(20):face;if(!goldFaces.has(result))throw RangeError('Not a D20 face: '+result);
  state.selected=result;state.visibleFace=null;state.busy=true;el('result').textContent='…';el('roll').disabled=true;
  htmlStatus('RNG выбрал '+result+' до начала вращения.');roll={from:current,to:uprightTarget(result),chosen:result,start:performance.now(),duration:1750};return result
 }
 function paint(now){state.frames++;const t0=performance.now();
  if(roll){const t=Math.min(1,(now-roll.start)/roll.duration),s=t*t*(3-2*t);const spin=qaxis([.65,.28,.7],Math.PI*4*(1-s));current=qnorm(qmul(spin,qslerp(roll.from,roll.to,s)));
   if(t>=1){current=roll.to;state.busy=false;state.visibleFace=roll.chosen;el('result').textContent=roll.chosen;el('roll').disabled=false;htmlStatus('RNG='+roll.chosen+' · золотая грань='+roll.chosen+' · GLB оригинал');roll=null;}}
  gl.viewport(0,0,canvas.width,canvas.height);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);
  if(state.ready){gl.useProgram(program);const die=qmat(current,[0,0,-2.65]);gl.uniformMatrix4fv(uniform.uDie,false,die);
   for(const piece of pieces){gl.bindVertexArray(piece.vao);gl.uniformMatrix4fv(uniform.uNode,false,piece.node);gl.uniform1i(uniform.uType,piece.matType);gl.uniform1i(uniform.uHasAlbedo,piece.base===undefined?0:1);gl.uniform1i(uniform.uHasNormal,piece.normal===undefined?0:1);gl.uniform3f(uniform.uBaseFactor,piece.baseFactor[0],piece.baseFactor[1],piece.baseFactor[2]);gl.uniform1f(uniform.uNormalScale,piece.normalScale);gl.uniform1f(uniform.uRoughness,piece.rough);gl.uniform1f(uniform.uMetalness,piece.metal);
    gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,piece.base===undefined?white:textures[piece.base]);gl.activeTexture(gl.TEXTURE1);gl.bindTexture(gl.TEXTURE_2D,piece.normal===undefined?flatNormal:textures[piece.normal]);gl.drawElements(gl.TRIANGLES,piece.count,piece.indType,piece.offset);state.drawCount++;}
  }
  state.lastDurationMs=performance.now()-t0;requestAnimationFrame(paint)
 }
 requestAnimationFrame(paint);
 el('roll').addEventListener('click',()=>chooseFace());
 el('asset').addEventListener('change',async e=>{const file=e.target.files[0];if(!file)return;el('roll').disabled=true;htmlStatus('Читаю GLB '+file.name+'...');try{const o=await loadGLB(await file.arrayBuffer(),file.name);console.info('REAL_PRIVATE_GLB_LOADED',o)}catch(err){state.error=String(err);htmlStatus(err.message,true);console.error(err)}});
 window.DiceExperimentalQA={state,loadGLB,setTarget,chooseFace,goldFaces:()=>new Map(goldFaces),orientation:(face)=>uprightTarget(face),letterUp:(face)=>qrot(current,glyphUpVectors.get(face)),rotatedNormal:(face)=>qrot(current,goldFaces.get(face)),rng:secureRoll,getGLError:()=>gl.getError(),gpuInfo:()=>({version:gl.getParameter(gl.VERSION),vendor:gl.getParameter(gl.VENDOR),renderer:gl.getParameter(gl.RENDERER)})};
})();