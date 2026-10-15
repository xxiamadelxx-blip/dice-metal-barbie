'use strict';
const assert=require('node:assert/strict'),crypto=require('node:crypto');
const {secureDie}=require('./load-source.cjs')('./rng-core.js');
for(const sides of [4,6,8,10,12,20,100]){
 const counts=new Int32Array(sides);
 for(let i=0;i<20000;i++){const v=secureDie(sides,crypto.webcrypto);assert(v>=1&&v<=sides);counts[v-1]++}
 assert(counts.every(x=>x>0),'Every face occurs');
}
let attempts=0;const fake={getRandomValues(out){out[0]=(attempts++===0?4294967295:42);return out}};
assert.equal(secureDie(20,fake),3);assert.equal(attempts,2);
assert.throws(()=>secureDie(1,crypto.webcrypto),RangeError);
assert.throws(()=>secureDie(20,null),/Secure RNG/);
console.log('PASS_RNG_FIRST_CRYPTO_REJECTION',140000,'rolls across D4,D6,D8,D10,D12,D20,D100; unbiased rejection gate checked');