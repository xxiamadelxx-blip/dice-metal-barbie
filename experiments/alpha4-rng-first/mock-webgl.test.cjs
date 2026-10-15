'use strict';
// GPU API integration contract: real 500k GLB buffers and draw-counts uploaded
// to a strictly checking mock WebGL2 context. This DOES NOT prove hardware FPS.
const fs=require('node:fs'),assert=require('node:assert/strict');
const {parse,verifyMaster,poseForNumber}=require('./load-source.cjs')('./glb-core.js');
const {Viewer}=require('./load-source.cjs')('./webgl-renderer.js');
const data=fs.readFileSync(process.argv[2]);const ab=data.buffer.slice(data.byteOffset,data.byteOffset+data.byteLength);const parsed=parse(ab),proof=verifyMaster(parsed);
let unique=0,bytesUploaded=0,indicesDrawn=0,drawCalls=0,texturesDecoded=0;
const gl={VERTEX_SHADER:35633,FRAGMENT_SHADER:35632,COMPILE_STATUS:35713,LINK_STATUS:35714,ARRAY_BUFFER:34962,ELEMENT_ARRAY_BUFFER:34963,STATIC_DRAW:35044,FLOAT:5126,UNSIGNED_SHORT:5123,UNSIGNED_INT:5125,UNSIGNED_BYTE:5121,TRIANGLES:4,RGBA:6408,UNSIGNED_BYTE:5121,TEXTURE_2D:3553,TEXTURE_MIN_FILTER:10241,TEXTURE_MAG_FILTER:10240,LINEAR:9729,LINEAR_MIPMAP_LINEAR:9987,TEXTURE_WRAP_S:10242,TEXTURE_WRAP_T:10243,REPEAT:10497,TEXTURE0:33984,DEPTH_TEST:2929,LEQUAL:515,CULL_FACE:2884,COLOR_BUFFER_BIT:16384,DEPTH_BUFFER_BIT:256,UNPACK_FLIP_Y_WEBGL:37440};
function next(){return {id:++unique}}
for(const f of ['createShader','createProgram','createBuffer','createVertexArray','createTexture'])gl[f]=next;
for(const f of ['shaderSource','compileShader','attachShader','linkProgram','useProgram','bindBuffer','bindVertexArray','bindTexture','vertexAttribPointer','enableVertexAttribArray','disableVertexAttribArray','vertexAttrib3f','texParameteri','texImage2D','pixelStorei','generateMipmap','enable','disable','depthFunc','clearColor','uniform1i','uniform1f','uniform4fv','uniformMatrix4fv','viewport','clear','activeTexture'])gl[f]=()=>{};
gl.getShaderParameter=()=>true;gl.getProgramParameter=()=>true;gl.getUniformLocation=()=>({});gl.bufferData=(target,payload)=>{assert(payload.byteLength>0);bytesUploaded+=payload.byteLength};
gl.drawElements=(mode,count,type,offset)=>{assert.equal(mode,gl.TRIANGLES);assert(count>0&&count%3===0);assert(type===gl.UNSIGNED_SHORT||type===gl.UNSIGNED_INT);assert(offset>=0);indicesDrawn+=count;drawCalls++};
let imageTypes=[];
globalThis.createImageBitmap=async(blob)=>{assert(blob.size>20);imageTypes.push(blob.type);texturesDecoded++;return{close(){}}};
const app=new Viewer({width:720,height:720,getContext:type=>type==='webgl2'?gl:null});
(async()=>{const result=await app.load(parsed);app.draw(poseForNumber(proof.labels,20));assert.equal(indicesDrawn,500000*3);assert.equal(drawCalls,result.drawCalls);assert.equal(result.drawCalls,22);assert.equal(texturesDecoded,parsed.json.images.length);assert(bytesUploaded>10000000);console.log('PASS_MOCK_GPU_500K_GLTF_PBR_UPLOAD',JSON.stringify({triangles:indicesDrawn/3,drawCalls,decodedPbrImageCount:texturesDecoded,uploadBytes:bytesUploaded,sourceBytes:parsed.sourceBytes}))})().catch(e=>{console.error(e);process.exitCode=1});