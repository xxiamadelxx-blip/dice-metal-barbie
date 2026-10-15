/* Cryptographically secure, rejection sampled unbiased die result.
 * Correct even for D100, future non-powers-of-two. Never Math.random for outcomes.
 */
(function(root){
'use strict';
function secureDie(sides,source=root.crypto){
 if(!Number.isInteger(sides)||sides<2||sides>1000000)throw RangeError('Die sides must be 2..1000000');
 if(!source||typeof source.getRandomValues!=='function')throw Error('Secure RNG unavailable');
 const buf=new Uint32Array(1),size=4294967296,limit=Math.floor(size/sides)*sides;
 do{source.getRandomValues(buf)}while(buf[0]>=limit);
 return buf[0]%sides+1;
}
root.DiceRNG={secureDie};if(typeof module!=='undefined'&&module.exports)module.exports=root.DiceRNG;
})(typeof window==='undefined'?globalThis:window);