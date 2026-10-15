import {chromium} from 'playwright';
import {readFileSync,mkdirSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import assert from 'node:assert/strict';
const output=resolve(process.env.EVIDENCE_DIR||'qa-output');
mkdirSync(output,{recursive:true});
const logs=[];
const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--disable-web-security','--no-sandbox']});
try{
 const page=await browser.newPage({viewport:{width:450,height:820},deviceScaleFactor:1});
 page.on('console',m=>{if(m.type()==='error')logs.push(m.text())});
 page.on('pageerror',e=>logs.push('PAGE_ERROR '+e.stack));
 await page.goto('http://127.0.0.1:8765/index.html',{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>window.__DICE_QA__?.ready===true,{timeout:60000});
 const data=await page.evaluate(async()=>{
   const q=window.__DICE_QA__;
   const results=[];
   for(let k=1;k<=20;k++){
     const result=await q.rollForTest(k,3);
     results.push(result);
   }
   return {renderer:q.renderer,engine:q.engine,usesGodot:q.usesGodot,
     usesJolt:q.usesJolt,faces:q.faces,webgl2:q.WebGL,
     chosenBeforeAnimation:q.chosenBeforeAnimation,results}
 });
 assert.equal(data.faces,20);
 assert.equal(data.usesGodot,false);
 assert.equal(data.usesJolt,false);
 assert.equal(data.chosenBeforeAnimation,true);
 assert.equal(data.results.length,20);
 for(let i=0;i<20;i++){
   const result=data.results[i];
   assert.equal(result.selected,i+1);
   assert.equal(result.topFace,i+1,'visible REAL 3D face must equal RNG value');
   assert(result.matches);
   assert(result.topDot>.9999,'face must point accurately up');
   assert(result.finished);
 }
 // Photograph actual rendered Browser/Three canvas with the GOLD 20 face UP.
 await page.evaluate(()=>window.__DICE_QA__.rollForTest(20,60));
 await page.waitForTimeout(400);
 assert.equal(await page.locator('#result').textContent(),'D20 / 20');
 const surface=await page.locator('canvas').evaluate(node=>({
   width:node.width,height:node.height,
   pixels:(()=>{const g=node.getContext('webgl2')||node.getContext('webgl');return Boolean(g)})()
 }));
 assert(surface.width>100&&surface.height>100&&surface.pixels);
 await page.screenshot({path:resolve(output,'real_threejs_webgl_rng_first_d20_20.png'),fullPage:true});
 await page.locator('#viewport').screenshot({path:resolve(output,'real_threejs_canvas_d20_20.png')});
 // Untrusted source must be rejected before a GLTF loader sees its bytes.
 await page.locator('#glbUpload').setInputFiles({name:'untrusted.glb',mimeType:'model/gltf-binary',buffer:Buffer.from('bad-model')});
 await page.waitForFunction(()=>document.getElementById('status')?.textContent?.includes('SHA-256'),null,{timeout:10000});
 assert.equal(await page.evaluate(()=>window.__DICE_QA__.modelSource),'PROCEDURAL_20_FACES');
 assert.equal(await page.locator('#result').textContent(),'D20 / 20');
 writeFileSync(resolve(output,'qa.json'),JSON.stringify({pass:true,source:'Playwright Chromium real Three.js WebGL',...data,
  browserCanvas:surface,corruptPrivateGlbRejected:true,consoleErrors:logs},null,2)+'\n');
 if(logs.length)throw new Error('Browser logged errors: '+logs.join('\n'));
 console.log('PASS_REAL_THREE_WEBGL_20_OF_20_FACE_PRESELECTED_RNG',JSON.stringify({
  faceCount:data.faces,rolls:data.results.length,shaderSource:'Three.js realtime WebGL',
  screenshot:'real_threejs_webgl_rng_first_d20_20.png',
  usedGodot:false}));
}finally{await browser.close()}
