/* Offline, dependency-free glTF 2 GLB parser + exact engraved face poses.
 * Source-only; the owner's licensed original GLB must remain private.
 */
(function(root){
'use strict';
const encoder=new TextDecoder('utf-8');
function parse(arrayBuffer){
 if(!(arrayBuffer instanceof ArrayBuffer))throw Error('Expected GLB ArrayBuffer');
 const d=new DataView(arrayBuffer);if(d.byteLength<20||d.getUint32(0,true)!==0x46546c67||d.getUint32(4,true)!==2||d.getUint32(8,true)!==d.byteLength)throw Error('Invalid glTF2 GLB header');
 let at=12,json=null,bin=null;
 while(at<d.byteLength){if(at+8>d.byteLength)throw Error('Short GLB chunk');const bytes=d.getUint32(at,true),type=d.getUint32(at+4,true);at+=8;if(at+bytes>d.byteLength)throw Error('GLB chunk beyond file');if(type===0x4e4f534a){json=JSON.parse(encoder.decode(new Uint8Array(arrayBuffer,at,bytes)).trim())}else if(type===0x004e4942){bin=new Uint8Array(arrayBuffer,at,bytes)}at+=bytes}
 if(!json||!bin||json.buffers?.length!==1||json.buffers[0].byteLength>bin.byteLength)throw Error('Unsupported GLB: missing embedded binary buffer');
 const view=id=>{const v=json.bufferViews[id];if(!v)throw Error('Missing bufferView '+id);const offset=v.byteOffset||0;if(offset+v.byteLength>bin.byteLength)throw Error('Out of bounds bufferView');return new Uint8Array(bin.buffer,bin.byteOffset+offset,v.byteLength)};
 const accessor=id=>{const a=json.accessors[id];if(!a||a.sparse||a.bufferView===undefined)throw Error('Sparse/missing accessor is unsupported');return a};
 return {json,bin,view,accessor,sourceBytes:arrayBuffer.byteLength};
}
function norm(x){const d=Math.hypot(...x);if(!d)throw Error('Zero vector');return x.map(v=>v/d)}
function cross(a,b){return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]}
function dot(a,b){return a.reduce((v,c,i)=>v+c*b[i],0)}
function qmul(a,b){return [a[3]*b[0]+a[0]*b[3]+a[1]*b[2]-a[2]*b[1],a[3]*b[1]-a[0]*b[2]+a[1]*b[3]+a[2]*b[0],a[3]*b[2]+a[0]*b[1]-a[1]*b[0]+a[2]*b[3],a[3]*b[3]-a[0]*b[0]-a[1]*b[1]-a[2]*b[2]]}
function qrot(q,v){const u=q.slice(0,3),t=cross(u,v).map(x=>x*2),uxt=cross(u,t);return v.map((x,i)=>x+q[3]*t[i]+uxt[i])}
function qaxis(axis,angle){const s=Math.sin(angle/2),n=norm(axis);return [...n.map(x=>x*s),Math.cos(angle/2)]}
function qface(a,b){const d=dot(a,b);if(d<-.999999){const trial=Math.abs(a[0])<.8?[1,0,0]:[0,1,0];return qaxis(cross(a,trial),Math.PI)}return norm([...cross(a,b),1+d])}
function slerp(a,b,t){let d=dot(a,b);if(d<0){b=b.map(x=>-x);d=-d}if(d>.9995)return norm(a.map((x,i)=>x+(b[i]-x)*t));const theta=Math.acos(Math.min(1,d)),denom=Math.sin(theta);return a.map((x,i)=>(x*Math.sin((1-t)*theta)+b[i]*Math.sin(t*theta))/denom)}
function labels(glb){const labels=new Map();for(const n of glb.json.nodes||[]){const m=/^Gold_(\d\d)$/.exec(n.name||'');if(!m)continue;const v=Number(m[1]);if(v<1||v>20||labels.has(v))throw Error('Invalid/multiple gold glyph '+v);const rotation=n.rotation||[0,0,0,1];const forward=norm(qrot(rotation,[0,1,0]));const tangent=norm(qrot(rotation,[0,0,1]));const tr=n.translation||[0,0,0];if(Math.hypot(...tr)<.1||dot(norm(tr),forward)<.995)throw Error('Glyph normal/center mismatch '+v);labels.set(v,{forward,tangent,translation:tr,node:n})}if(labels.size!==20)throw Error('Source D20 must have exactly 20 Gold_XX nodes, got '+labels.size);return labels}
function poseForNumber(labelMap,n){const f=labelMap.get(n);if(!f)throw RangeError('D20 number must be 1..20');const toCam=qface(f.forward,[0,0,1]);const up=qrot(toCam,f.tangent);const roll=qaxis([0,0,1],Math.atan2(up[0],up[1]));const q=norm(qmul(roll,toCam));return q}
function countTriangles(glb){let total=0;for(const n of glb.json.nodes||[]){if(n.mesh===undefined)continue;for(const p of glb.json.meshes[n.mesh].primitives){if(p.mode!==undefined&&p.mode!==4)throw Error('GLB must be triangle mode');const c=glb.accessor(p.indices??p.attributes.POSITION).count;if(c%3)throw Error('Nontriangle index count');total+=c/3}}return total}
function verifyMaster(glb){const labelsMap=labels(glb);const tris=countTriangles(glb);if(tris!==500000)throw Error('Expected selected 500k original D20, got '+tris);return {labels:labelsMap,triangles:tris,meshNodes:glb.json.nodes.filter(n=>n.mesh!==undefined).length}}
root.DiceGLB={parse,labels,poseForNumber,countTriangles,verifyMaster,norm,qmul,qrot,qaxis,slerp,dot};
if(typeof module!=='undefined'&&module.exports)module.exports=root.DiceGLB;
})(typeof window==='undefined'?globalThis:window);