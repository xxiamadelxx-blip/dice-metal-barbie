/** RNG-first dice model; independent of Godot/Jolt/Three.js.
 * Uses system Web Crypto for each die. Never infer outcome from a simulated
 * collision; simulated animation MUST align to this immutable chosen target.
 */
export const FACE_VALUES = Object.freeze([
  6,1,5,10,13,2,12,18,14,4,11,16,20,15,8,7,17,19,9,3
]);
export const ICO_FACES = Object.freeze([
  [0,11,5],[0,5,1],[0,1,7],[0,7,10],[0,10,11],
  [1,5,9],[5,11,4],[11,10,2],[10,7,6],[7,1,8],
  [3,9,4],[3,4,2],[3,2,6],[3,6,8],[3,8,9],
  [4,9,5],[2,4,11],[6,2,10],[8,6,7],[9,8,1]
]);
const PHI=(1+Math.sqrt(5))/2;
export const ICO_VERTICES=Object.freeze([
  [-1,PHI,0],[1,PHI,0],[-1,-PHI,0],[1,-PHI,0],
  [0,-1,PHI],[0,1,PHI],[0,-1,-PHI],[0,1,-PHI],
  [PHI,0,-1],[PHI,0,1],[-PHI,0,-1],[-PHI,0,1]
].map(v=>{const len=Math.hypot(...v);return Object.freeze(v.map(x=>x/len));}));
const sub=(a,b)=>a.map((x,i)=>x-b[i]);
const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const dot=(a,b)=>a.reduce((s,x,i)=>s+x*b[i],0);
const unit=(a)=>{const len=Math.hypot(...a);return a.map(x=>x/len)};
export const FACE_NORMALS=Object.freeze(ICO_FACES.map(([i,j,k])=>Object.freeze(
  unit(cross(sub(ICO_VERTICES[j],ICO_VERTICES[i]),sub(ICO_VERTICES[k],ICO_VERTICES[i])))
)));
export function faceForValue(value) {
  const index=FACE_VALUES.indexOf(value);
  if(index<0)throw new RangeError('Not a numbered D20 face: '+value);
  return index;
}
export function measuredFace(quaternion) {
  if(!quaternion||!['x','y','z','w'].every(k=>Number.isFinite(quaternion[k])))
    throw new TypeError('Expected finite quaternion');
  const {x,y,z,w}=quaternion;
  const len=Math.hypot(x,y,z,w);
  if(Math.abs(len-1)>.01)throw new RangeError('Quaternion not normalized');
  // World-space Y component of (q * normal * q^-1).
  let winner=-1,best=-Infinity,second=-Infinity;
  for(let i=0;i<20;i++){
    const [nx,ny,nz]=FACE_NORMALS[i];
    const up=2*(x*y+z*w)*nx+(1-2*(x*x+z*z))*ny+2*(y*z-x*w)*nz;
    if(up>best){second=best;best=up;winner=i}
    else if(up>second)second=up;
  }
  return {faceIndex:winner,value:FACE_VALUES[winner],upDot:best,separation:best-second};
}
export function assertD20Contract(){
  if(FACE_VALUES.length!==20||new Set(FACE_VALUES).size!==20||FACE_VALUES.some(n=>n<1||n>20))
    throw new Error('D20 engraved numbers not bijective');
  let oppositeCount=0;
  for(let i=0;i<20;i++){
    const j=FACE_NORMALS.findIndex((n,k)=>k!==i&&dot(n,FACE_NORMALS[i])<-.9999);
    if(j<0||FACE_VALUES[i]+FACE_VALUES[j]!==21)throw new Error('D20 opposite face mapping broken: '+i);
    oppositeCount++;
  }
  return oppositeCount===20;
}
export function cryptoDie(sides,source=globalThis.crypto){
  if(!Number.isInteger(sides)||sides<2||sides>1000)throw new RangeError('Unsupported die d'+sides);
  if(!source||typeof source.getRandomValues!=='function')throw new Error('Secure crypto.getRandomValues required; no Math.random fallback');
  const threshold=Math.floor(4294967296/sides)*sides;
  const buf=new Uint32Array(1);
  let value;
  do {source.getRandomValues(buf);value=buf[0]} while(value>=threshold);
  return 1+(value%sides);
}
export function makeRoll(mode='d20',draw=cryptoDie){
  const drawOne=(s)=>{const value=draw(s);if(!Number.isInteger(value)||value<1||value>s)throw new RangeError('Invalid RNG value');return value};
  const id=mode;
  if(mode==='d20'){
    const value=drawOne(20);
    return Object.freeze({mode:id,result:value,visualD20:value,rolls:Object.freeze([{type:'d20',value}])});
  }
  if(mode==='advantage'||mode==='disadvantage'){
    const a=drawOne(20),b=drawOne(20);
    const chosen=mode==='advantage'?Math.max(a,b):Math.min(a,b);
    return Object.freeze({mode:id,result:chosen,visualD20:chosen,rolls:Object.freeze([
      {type:'d20',value:a},{type:'d20',value:b}
    ])});
  }
  if(mode==='mixed'){
    const d20=drawOne(20),d6a=drawOne(6),d6b=drawOne(6);
    return Object.freeze({mode:id,result:d20+d6a+d6b,visualD20:d20,
      rolls:Object.freeze([{type:'d20',value:d20},{type:'d6',value:d6a},{type:'d6',value:d6b}])});
  }
  throw new RangeError('Unknown roll preset: '+mode);
}
assertD20Contract();
