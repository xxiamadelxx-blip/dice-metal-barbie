'use strict';
// Source-only glTF 2.0 material semantics regression; no licensed bytes in public repo.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const viewer=fs.readFileSync(path.join(__dirname,'../viewer.js'),'utf8');
assert(viewer.includes('metal:pbr.metallicFactor??1'),'glTF 2.0 default metallicFactor is 1.0, not 0.0');
assert(viewer.includes('rough:pbr.roughnessFactor??1'),'glTF 2.0 default roughnessFactor is 1.0');
assert(viewer.includes('normalScale:mat.normalTexture?.scale??1'),'glTF normalTexture.scale must be read from asset');
assert(viewer.includes('linearBase*=pow(albedo,vec3(2.2))'),'albedo image and linear base factor must multiply');
assert(viewer.includes('gl.uniform3f(uniform.uBaseFactor,piece.baseFactor[0]'),'material baseFactor must reach the shader');
assert(!viewer.includes('uGoldBase'),'source gold color must not be hardcoded');
if(process.argv[2]){
 const data=fs.readFileSync(process.argv[2]);assert.equal(data.toString('ascii',0,4),'glTF');
 assert.equal(data.readUInt32LE(4),2);const len=data.readUInt32LE(12);
 const gltf=JSON.parse(data.subarray(20,20+len).toString('utf8'));
 const gold=gltf.materials.find(m=>m.name==='GoldRecessedNoEmission');
 assert(gold,'expected owner source gold material');
 const pbr=gold.pbrMetallicRoughness;
 assert.equal(pbr.metallicFactor??1,1);
 assert(Math.abs(pbr.baseColorFactor[0]-.56)<1e-5);
 assert(Math.abs(pbr.baseColorFactor[1]-.335)<1e-5);
 assert(Math.abs(pbr.baseColorFactor[2]-.105)<1e-5);
 console.log('PASS_OWNER_SOURCE_GOLD_MATERIAL_GLTF2_DEFAULT',JSON.stringify(pbr));
}
console.log('PASS_GLTF2_SOURCE_PBR_MATERIAL_CONTRACT');
