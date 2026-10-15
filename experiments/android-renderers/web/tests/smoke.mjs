import { chromium } from 'playwright-core';
import { readFileSync, mkdirSync, writeFileSync, statSync } from 'node:fs';
import { join } from 'node:path';

const BASE_URL = process.env.RENDER_LAB_URL ?? 'http://127.0.0.1:4173/';
const ARTIFACT_DIR = process.env.RENDER_LAB_EVIDENCE ?? './build/browser-evidence';
const TEST_GLB = process.env.RENDER_LAB_TEST_GLB ?? './build/synthetic_nonpremium_500k.glb';
const executable = process.env.CHROME_BIN
  ?? ['/usr/bin/google-chrome','/usr/bin/chromium'].find(p=>{try{return statSync(p).isFile()}catch{return false}});
if(!executable)throw new Error('Chromium executable missing; do not claim 3D smoke passed');
mkdirSync(ARTIFACT_DIR,{recursive:true});
const browser=await chromium.launch({headless:true,executablePath:executable,
 args:['--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader',
       '--enable-unsafe-swiftshader','--disable-gpu-sandbox','--enable-webgl']});
let result;
try{
  const context=await browser.newContext({viewport:{width:430,height:860},deviceScaleFactor:1});
  const page=await context.newPage();
  const errors=[];
  page.on('pageerror',x=>errors.push(String(x)));
  page.on('console',msg=>{if(msg.type()==='error')errors.push(msg.text())});
  // No CDN/network is necessary, because the Three.js ESM code is bundled.
  await page.route('**/*', async route=>{
    const request=route.request();
    const url=new URL(request.url());
    if(url.hostname==='127.0.0.1'||url.hostname==='localhost')return route.continue();
    errors.push('EXTERNAL_NETWORK_ATTEMPT '+request.url());
    return route.abort();
  });
  await page.goto(BASE_URL,{waitUntil:'networkidle',timeout:60000});
  await page.waitForFunction(()=>window.__diceLab?.state?.includes('WebGL2 работает'),{timeout:45000});
  // Real THREE WebGL2 die roll with preselected crypto outcome and animated
  // visually matching gold number. No 500k original PBR published to CI.
  await page.locator('#roll-d20').click();
  await page.waitForFunction(()=>window.__diceLab?.rollCount===1 && !window.__diceLab?.rolling,
    {timeout:30000});
  const firstRoll=await page.evaluate(()=>{
    const l=window.__diceLab;
    return {target:l.lastTarget,visible:l.lastVisible,rolls:l.rollCount,
      result:l.lastResult,mechanics:l.mechanics,history:l.rollHistory};
  });
  if(firstRoll.target!==firstRoll.visible||firstRoll.target!==firstRoll.result)
    throw new Error('RNG-FIRST D20 VISIBLE FACE FAILURE '+JSON.stringify(firstRoll));
  if(firstRoll.mechanics!=='RNG-FIRST_TARGET_THEN_SCRIPTED_KINEMATIC_3D_NOT_RIGIDBODY')
    throw new Error('Wrong RNG-first vs Jolt contract');
  await page.screenshot({path:join(ARTIFACT_DIR,'REAL_THREE_ALPHA4_RNG_FIRST_NUMBERED_D20.png'),
    fullPage:true,animations:'disabled'});
  await page.locator('#roll-mixed').click();
  await page.waitForFunction(()=>window.__diceLab?.rollCount===2&&!window.__diceLab?.rolling,
    {timeout:30000});
  const mixedRoll=await page.evaluate(()=>{
    const l=window.__diceLab;
    return {chosen:l.currentPlan.visualD20,sum:l.currentPlan.result,
      actualVisual:l.lastVisible,dice:l.currentPlan.rolls};
  });
  if(mixedRoll.chosen!==mixedRoll.actualVisual ||
      mixedRoll.dice.length!==3 ||
      mixedRoll.sum!==mixedRoll.dice.reduce((a,x)=>a+x.value,0))
    throw new Error('Mixed RNG-first discrepancy '+JSON.stringify(mixedRoll));
  console.log('PASS_REAL_THREE_ALPHA4_RNG_FIRST',JSON.stringify({firstRoll,mixedRoll}));
  const before=await page.evaluate(()=>({state:window.__diceLab.state,frames:window.__diceLab.renderedFrames,
    webgl:window.__diceLab.glVersion}));
  if(!String(before.webgl).includes('WebGL 2.0'))throw new Error('Browser did not create REAL WebGL2 GPU context');
  await page.locator('#model-file').setInputFiles({
    name:'SYNTHETIC_NOT_OWNER_500000.glb',mimeType:'model/gltf-binary',buffer:readFileSync(TEST_GLB)
  });
  await page.waitForFunction(()=>window.__diceLab?.modelTriangles===500000&&window.__diceLab?.modelLoaded,
    {timeout:120000});
  await page.waitForFunction(()=>window.__diceLab?.drawTriangles>=500000&&window.__diceLab?.renderedFrames>=20,
    {timeout:120000});
  result=await page.evaluate(()=>{
    const l=window.__diceLab;
    return {
      renderer:l.renderer,glVersion:l.glVersion,glVendor:l.glVendor,state:l.state,
      modelTriangles:l.modelTriangles,renderedTriangles:l.drawTriangles,
      goldMeshes:l.goldMeshes,sourceOriginal:l.exactOriginal,drawCalls:l.drawCalls,
      completedFrames:l.renderedFrames,roughFps:l.fps,renderCamera:l.camera,
      isSynthetic:l.demo===false&&!l.exactOriginal,
      errors:l.error
    };
  });
  if(result.modelTriangles!==500000||result.renderedTriangles<500000)
    throw new Error('GLB actual load / rendered triangles not 500000: '+JSON.stringify(result));
  if(result.sourceOriginal)throw new Error('Synthetic test GLB must never be reported as the original');
  // Unverified GLB doesn't have authenticated face/number mapping. Never
  // animate the wrong golden face against an RNG target.
  const unavailable=await page.locator('#roll-d20').isDisabled();
  if(!unavailable)throw new Error('Unverified GLB incorrectly enabled guaranteed-number animation');
  if(errors.length)throw new Error('Browser JS/CDN errors: '+JSON.stringify(errors.slice(0,10)));
  await page.screenshot({path:join(ARTIFACT_DIR,'REAL_THREE_WEBGL2_SYNTHETIC_500K_NOT_OBSIDIAN.png'),
    fullPage:true,animations:'disabled'});
  const bytes=statSync(join(ARTIFACT_DIR,'REAL_THREE_WEBGL2_SYNTHETIC_500K_NOT_OBSIDIAN.png')).size;
  if(bytes<15000)throw new Error('Blank screenshot or missing canvas '+bytes);
  writeFileSync(join(ARTIFACT_DIR,'real_three_webgl2_500k_smoke.json'),
    JSON.stringify({...result,screenshotBytes:bytes,
      caveat:'Synthetic 500k geometry, NOT owner original, NOT Android GPU/Jolt FPS, not compared Godot on same device.'},null,2)+'\n');
  console.log('PASS_ACTUAL_THREE_WEBGL2_500K_IN_BROWSER',JSON.stringify(result));
  await context.close();
}finally{
 await browser.close();
}
