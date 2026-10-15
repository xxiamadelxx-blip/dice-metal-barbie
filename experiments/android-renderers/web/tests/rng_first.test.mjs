import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from 'three';
import {FACE_VALUES,FACE_NORMALS,ICO_FACES,assertD20Contract,
  cryptoDie,makeRoll,measuredFace} from '../src/rng_first.mjs';
import {quaternionForPrintedFace,animateToPrintedFace} from '../src/dice_animation.js';

test('20 genuine canonical face indices: unique engraved labels and antipodes 21',()=>{
  assert.equal(assertD20Contract(),true);
  assert.equal(new Set(FACE_VALUES).size,20);
  assert.equal(ICO_FACES.length,20);
  for(let i=0;i<20;i++){
    const antipode=FACE_NORMALS.findIndex((v,j)=>j!==i&&
      FACE_NORMALS[i].reduce((s,x,k)=>s+x*v[k],0)<-.99999);
    assert.ok(antipode>=0,'missing antipodal face');
    assert.equal(FACE_VALUES[i]+FACE_VALUES[antipode],21);
  }
});
test('crypto RNG uint32 rejection prevents modulo bias, no Math.random fallback',()=>{
  const values=[4294967295,4294967280,7];
  let calls=0;
  const mock={getRandomValues(a){a[0]=values[calls++];return a}};
  assert.equal(cryptoDie(20,mock),8);
  assert.equal(calls,3);
  assert.throws(()=>cryptoDie(20,{}),/Secure crypto/);
  assert.throws(()=>cryptoDie(0,mock),/Unsupported die/);
});
test('RNG decisions are generated FIRST for d20, advantage and mixed rolls',()=>{
  const values=[5,8,16,14,2,4,6,3];
  const draw=(faces)=>{const r=values.shift();assert.ok(r<=faces);return r};
  const d20=makeRoll('d20',draw);
  assert.equal(d20.result,5);assert.equal(d20.visualD20,5);
  const adv=makeRoll('advantage',draw);
  assert.deepEqual(adv.rolls.map(x=>x.value),[8,16]);
  assert.equal(adv.visualD20,16);
  const disadv=makeRoll('disadvantage',draw);
  assert.deepEqual(disadv.rolls.map(x=>x.value),[14,2]);
  assert.equal(disadv.visualD20,2);
  const mixed=makeRoll('mixed',draw);
  assert.deepEqual(mixed.rolls.map(x=>x.value),[4,6,3]);
  assert.equal(mixed.result,13);
  assert.equal(mixed.visualD20,4);
  assert.throws(()=>{d20.result=10},TypeError);
});
test('Every result 1..20 gets the correct TOP geometry face, no Godot or Jolt',()=>{
  for(let value=1;value<=20;value++){
    for(const yaw of [0,Math.PI/3,Math.PI,5.25]){
      const q=quaternionForPrintedFace(value,yaw);
      const m=measuredFace(q);
      assert.equal(m.value,value,'selected engraved number '+value);
      assert.ok(m.upDot>.999999,'upright alignment for '+value);
      assert.ok(m.separation>.1,'unique stable upward face '+value);
    }
  }
});
test('2.3s animated scripted roll ends at originally committed face',async()=>{
  const value=17,object=new THREE.Group(),queue=[];
  let clock=1000;
  const animationFrame=callback=>{queue.push(callback)};
  const promise=animateToPrintedFace(object,value,{
    duration:2300,now:()=>1000,animationFrame,
    randomDie:()=>1
  });
  for(let t=1100;t<=3300;t+=100){
    assert.ok(queue.length,'renderer must request animation frames');
    queue.shift()(t);
  }
  const end=await promise;
  assert.equal(end.visible,17);
  assert.equal(end.target,17);
  assert.ok(end.angleDot>.999);
  assert.ok(Math.abs(object.position.y-.06)<.0001);
  assert.equal(measuredFace(object.quaternion).value,17);
  assert.equal(queue.length,0);
});
