'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),crypto=require('node:crypto');
const {parse,verifyMaster,poseForNumber,qrot,dot,labels}=require('./load-source.cjs')('./glb-core.js');
const file=process.argv[2];if(!file)throw Error('Pass private original GLB filepath');
const bytes=fs.readFileSync(file);const ab=bytes.buffer.slice(bytes.byteOffset,bytes.byteOffset+bytes.byteLength);const g=parse(ab),v=verifyMaster(g);
assert.equal(v.triangles,500000);assert.equal(v.labels.size,20);assert.equal(v.meshNodes,21);
for(let n=1;n<=20;n++){
 const frame=v.labels.get(n),q=poseForNumber(v.labels,n);
 assert(dot(qrot(q,frame.forward),[0,0,1])>.999999999,`face alignment ${n}`);
 assert(dot(qrot(q,frame.tangent),[0,1,0])>.999999999,`gold label readability ${n}`);
 assert(Math.abs(Math.hypot(...q)-1)<1e-8,`quaternion normalization ${n}`);
}
assert.throws(()=>poseForNumber(v.labels,0),RangeError);
assert.throws(()=>poseForNumber(v.labels,21),RangeError);
console.log('PASS_ACTUAL_PRIVATE_500K_WEBGL_GLB',JSON.stringify({sha256:crypto.createHash('sha256').update(bytes).digest('hex'),byteLength:bytes.length,triangles:v.triangles,goldFaces:v.labels.size,meshNodes:v.meshNodes,exactFaceAndGoldUprightQuaternionChecks:20}));