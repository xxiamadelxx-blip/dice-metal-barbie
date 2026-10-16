#!/usr/bin/env node
'use strict';
// Independent source-extracted invariants: fails if the app's actual math regresses.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const crypto=require('node:crypto');
const root=path.resolve(__dirname,'..');
const jsFile=fs.existsSync(path.join(root,'viewer.js'))?path.join(root,'viewer.js'):path.resolve(__dirname,'viewer_sha_qa.js');
const js=fs.readFileSync(jsFile,'utf8');
function findLine(name){const regex=new RegExp('^const '+name+'=.*;$','m'),m=js.match(regex);assert(m,'missing '+name);return m[0]}
const helpers=['unit','dot','cross','qmul','qnorm','qaxis','qfrom','qrot'];
const SHA_START='/** Offline SHA-256 fallback';
const SHA_END='async function loadGLB';
const a=js.indexOf(SHA_START),z=js.indexOf(SHA_END);
assert(a>=0&&z>a,'SHA fallback not present in production viewer.js');
const sha=js.slice(a,z);
const start=js.indexOf('function uprightTarget(face)');
const end=js.indexOf('function setTarget(face)',start);
assert(start>=0&&end>start,'source 20-face upright target missing');
const upright=js.slice(start,end);
const context=vm.createContext({Uint8Array,Uint32Array,DataView,Math,Array,Map,globalThis:{},Error});
vm.runInContext(helpers.map(findLine).join('\n')+'\n'+sha+'\n'+upright,context);
const call=expr=>vm.runInContext(expr,context);
const buf=b=>b.buffer.slice(b.byteOffset,b.byteOffset+b.byteLength);
for(const test of ['', 'abc','The quick brown fox jumps over the lazy dog','☃'.repeat(72)]){
 const b=Buffer.from(test,'utf8');const actual=context.sha256Fallback(buf(b));const expected=crypto.createHash('sha256').update(b).digest('hex');assert.equal(actual,expected);
}
const rand=Buffer.alloc(1024*1024);for(let i=0;i<rand.length;i++)rand[i]=i&255;
assert.equal(context.sha256Fallback(buf(rand)),crypto.createHash('sha256').update(rand).digest('hex'));
const q1=call('qaxis([1,0,0],0.73)'),q2=call('qaxis([0,1,0],1.39)'),vec=[.27,.46,.89];
context.Q1=q1;context.Q2=q2;context.V=vec;
const comp=call('qrot(qmul(Q1,Q2),V)'),expected=call('qrot(Q1,qrot(Q2,V))');
for(let i=0;i<3;i++)assert(Math.abs(comp[i]-expected[i])<1e-9,'Incorrect quaternion Hamilton product');
function testGLB(file,original){
 const raw=fs.readFileSync(file);assert.equal(raw.toString('ascii',0,4),'glTF');
 const sz=raw.readUInt32LE(12),j=JSON.parse(raw.subarray(20,20+sz).toString('utf8'));
 const gold=j.nodes.filter(n=>/^Gold_\d{1,2}$/.test(n.name||''));assert.equal(gold.length,20);
 const normals=gold.map(n=>[Number(n.name.split('_')[1]),n.translation]);
 const rotations=gold.map(n=>[Number(n.name.split('_')[1]),n.rotation||[0,0,0,1]]);
 context.REAL_NORMALS=normals;context.REAL_ROTATIONS=rotations;context.GOLD_UP=original?[0,0,-1]:[0,1,0];
 vm.runInContext(`const goldFaces=new Map(REAL_NORMALS.map(([v,p])=>[v,unit(p)]));
 const glyphUpVectors=new Map(REAL_ROTATIONS.map(([v,q])=>[v,qrot(q,GOLD_UP)]));`,context);
 for(let val=1;val<=20;val++){
  context.FACE=val;
  const out=call('(()=>{const q=uprightTarget(FACE);const n=qrot(q,goldFaces.get(FACE));const up=qrot(q,glyphUpVectors.get(FACE));return {n,up}})()');
  assert(out.n[2]>0.999999999,`face ${val} not facing camera: ${JSON.stringify(out.n)}`);
  assert(out.up[1]>0.98&&Math.abs(out.up[0])<1e-6,`face ${val} glyph not upright: ${JSON.stringify(out.up)}`);
 }
 if(original){const approved='60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39';assert.equal(context.sha256Fallback(buf(raw)),approved)}
 return {model:original?'PRIVATE_ORIGINAL':'SYNTHETIC_PUBLIC',faceOrientation:20,triangles:original?500000:40};
}
const model=process.argv[2]||path.join(root,'android-app/app/src/main/assets/qa_fixture.glb');
const out=testGLB(model,process.argv.includes('--private'));
console.log('PASS_SOURCE_SHA256_AND_HAMILTON_AND_20_UPRIGHT_FACE_ORIENTATIONS',JSON.stringify(out));