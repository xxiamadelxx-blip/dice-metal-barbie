"use strict";
const assert=require("node:assert/strict");
const {secureDie}=require("./rng.cjs");
const crypto=require("node:crypto").webcrypto;
for(const sides of [4,6,8,10,12,20,100]){
  const seen=new Set();
  for(let i=0;i<20000;i++){const v=secureDie(sides,crypto);assert(v>=1&&v<=sides);seen.add(v)}
  assert.equal(seen.size,sides);
}
let calls=0;
const fake={getRandomValues(a){a[0]=calls++===0?4294967295:42;return a}};
assert.equal(secureDie(20,fake),3);
assert.equal(calls,2);
assert.throws(()=>secureDie(1,crypto),RangeError);
assert.throws(()=>secureDie(20,null),/Secure RNG/);
console.log("PASS RNG 7 die types × 20000 throws, coverage, rejection-sampling boundary, no insecure fallback");
