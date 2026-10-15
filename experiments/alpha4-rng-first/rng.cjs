"use strict";
function secureDie(sides,random=globalThis.crypto){
  if(!Number.isInteger(sides)||sides<2||sides>1000)throw new RangeError("invalid sides");
  if(!random||typeof random.getRandomValues!=="function")throw Error("Secure RNG unavailable");
  const span=4294967296,limit=Math.floor(span/sides)*sides,buf=new Uint32Array(1);
  do{random.getRandomValues(buf)}while(buf[0]>=limit);
  return (buf[0]%sides)+1;
}
if(typeof module!=="undefined")module.exports={secureDie};
