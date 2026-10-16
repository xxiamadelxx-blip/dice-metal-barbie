'use strict';
// WebGL2 original GLB Android WebView texture fallback contract: do not ship ImageBitmap-only.
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');
const src=fs.readFileSync(path.join(__dirname,'../viewer.js'),'utf8');
assert(src.includes("if(typeof createImageBitmap==='function')"),'ImageBitmap must be feature-detected');
assert(src.includes("return await new Promise((resolve,reject)=>"),'HTMLImageElement fallback missing');
assert(src.includes('URL.createObjectURL(blob)'), 'No Blob URL fallback');
assert(src.includes('URL.revokeObjectURL(url)'), 'Temp URLs must be freed on success and error');
assert(src.includes("typeof ImageBitmap==='undefined'||!(bmp instanceof ImageBitmap)"),'HTMLImageElement requires proper UNPACK_FLIP_Y_WEBGL');
assert(src.includes('gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,false)'),'Pixel unpack must restore default state');
console.log('PASS_ANDROID_WEBVIEW_GLB_TEXTURE_DECODE_SOURCE_CONTRACT');
