/* WebGL2 PBR original-owner-GLB viewer: zero third-party dependencies.
 * Renders all source mesh primitives (stone + 20 engraved gold digits).
 * Original 2k tangent normal map, roughness and base color are respected.
 * There is NO random-face physics: caller chooses a cryptographic RNG result first.
 */
(function(root){
'use strict';
const VS=`#version 300 es
precision highp float;
layout(location=0) in vec3 position;
layout(location=1) in vec3 normal;
layout(location=2) in vec2 texcoord;
uniform mat4 u_projection,u_die,u_node;
out vec3 vP,vN;out vec2 vUV;
void main(){vec4 world=u_die*u_node*vec4(position,1.0);vP=world.xyz;vN=mat3(u_die*u_node)*normal;vUV=texcoord;gl_Position=u_projection*world;}`;
const FS=`#version 300 es
precision highp float;
in vec3 vP,vN;in vec2 vUV;out vec4 outColor;
uniform sampler2D u_baseTex,u_normalTex,u_mrTex;
uniform bool u_hasBase,u_hasNormal,u_hasMR;
uniform vec4 u_color;uniform float u_roughness,u_metallic,u_normalScale;
uniform float u_studioStrength;
const float PI=3.141592653589793;
vec3 fresnelSchlick(float cosTheta,vec3 f0){return f0+(1.0-f0)*pow(1.0-clamp(cosTheta,0.0,1.0),5.0);}
float distributionGGX(float NdotH,float rough){float a=rough*rough,a2=a*a,d=(NdotH*NdotH*(a2-1.0)+1.0);return a2/max(PI*d*d,0.0001);}
float geometryG(float ndotv,float k){return ndotv/(ndotv*(1.0-k)+k);}
vec3 tonemap(vec3 v){v=max(v,vec3(0.0));return clamp((v*(2.51*v+0.03))/(v*(2.43*v+0.59)+0.14),0.0,1.0);}
vec3 diffuseSpec(vec3 N,vec3 V,vec3 L,vec3 base,float metallic,float rough,vec3 radiance){
 vec3 H=normalize(V+L);
 float nl=max(dot(N,L),0.0),nv=max(dot(N,V),0.0001),nh=max(dot(N,H),0.0),vh=max(dot(V,H),0.0);
 vec3 f0=mix(vec3(0.04),base,metallic),f=fresnelSchlick(vh,f0);
 float d=distributionGGX(nh,rough),k=pow(rough+1.0,2.0)/8.0;
 float g=geometryG(nl,k)*geometryG(nv,k);
 vec3 spec=f*(d*g/max(4.0*nl*nv,0.0001));
 vec3 diff=(vec3(1.0)-f)*(1.0-metallic)*base/PI;
 return (diff+spec)*radiance*nl;
}
void main(){
 vec3 base=u_color.rgb;
 if(u_hasBase)base*=pow(texture(u_baseTex,vUV).rgb,vec3(2.2));
 vec3 N=normalize(vN);
 if(u_hasNormal){vec3 dp1=dFdx(vP),dp2=dFdy(vP);vec2 duv1=dFdx(vUV),duv2=dFdy(vUV);
 vec3 T=normalize(dp1*duv2.y-dp2*duv1.y),B=normalize(-dp1*duv2.x+dp2*duv1.x);
 vec3 nm=texture(u_normalTex,vUV).xyz*2.0-1.0;nm.xy*=u_normalScale;
 if(length(cross(T,B))>0.01)N=normalize(mat3(T,B,N)*normalize(nm));}
 float rough=clamp(u_roughness,0.055,1.0),metal=clamp(u_metallic,0.0,1.0);
 if(u_hasMR){vec4 mr=texture(u_mrTex,vUV);rough=clamp(rough*mr.g,0.055,1.0);metal*=mr.b;}
 vec3 V=normalize(-vP);
 vec3 key=normalize(vec3(-0.45,0.78,0.8)),fill=normalize(vec3(0.8,0.5,0.3));
 vec3 color=diffuseSpec(N,V,key,base,metal,rough,vec3(4.1,4.4,4.8));
 color+=diffuseSpec(N,V,fill,base,metal,rough,vec3(0.72,0.55,0.3));
 // Soft circular photographic diffuser is a DIRECTIONAL REFLECTION from light,
 // computed dynamically in the BRDF. No highlights are painted into original maps.
 vec3 R=reflect(-V,N),diskDir=normalize(vec3(-0.13,0.87,0.47));
 float disc=pow(max(dot(R,diskDir),0.0),mix(70.0,4.0,rough));
 vec3 f0=mix(vec3(0.04),base,metal);
 color+=fresnelSchlick(max(dot(N,V),0.0),f0)*disc*(u_studioStrength*1.8);
 color+=base*(1.0-metal)*vec3(0.055,0.06,0.072);
 outColor=vec4(pow(tonemap(color),vec3(1.0/2.2)),u_color.a);
}`;
const normalize=a=>{const l=Math.hypot(...a);return a.map(x=>x/l)};
function mul(a,b){const out=new Float32Array(16);for(let c=0;c<4;c++)for(let r=0;r<4;r++)for(let k=0;k<4;k++)out[c*4+r]+=a[k*4+r]*b[c*4+k];return out}
function matTRS(translation=[0,0,0],q=[0,0,0,1],s=[1,1,1]){const [x,y,z,w]=q,[sx,sy,sz]=s;return new Float32Array([
 (1-2*(y*y+z*z))*sx,2*(x*y+z*w)*sx,2*(x*z-y*w)*sx,0,
 2*(x*y-z*w)*sy,(1-2*(x*x+z*z))*sy,2*(y*z+x*w)*sy,0,
 2*(x*z+y*w)*sz,2*(y*z-x*w)*sz,(1-2*(x*x+y*y))*sz,0,
 ...translation,1]);}
function perspective(fovy,aspect,near,far){const f=1/Math.tan(fovy/2);return new Float32Array([f/aspect,0,0,0,0,f,0,0,0,0,(far+near)/(near-far),-1,0,0,2*far*near/(near-far),0])}
function compile(gl,type,source){const x=gl.createShader(type);gl.shaderSource(x,source);gl.compileShader(x);if(!gl.getShaderParameter(x,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(x));return x}
function program(gl){const p=gl.createProgram();gl.attachShader(p,compile(gl,gl.VERTEX_SHADER,VS));gl.attachShader(p,compile(gl,gl.FRAGMENT_SHADER,FS));gl.linkProgram(p);if(!gl.getProgramParameter(p,gl.LINK_STATUS))throw Error(gl.getProgramInfoLog(p));return p}
class Viewer{
 constructor(canvas){this.canvas=canvas;this.gl=canvas.getContext('webgl2',{alpha:false,depth:true,antialias:true,powerPreference:'high-performance'});if(!this.gl)throw Error('WebGL2 недоступен в этом браузере');const gl=this.gl;this.prog=program(gl);gl.useProgram(this.prog);this.uniforms={};for(const name of ['u_projection','u_die','u_node','u_baseTex','u_normalTex','u_mrTex','u_hasBase','u_hasNormal','u_hasMR','u_color','u_roughness','u_metallic','u_normalScale','u_studioStrength'])this.uniforms[name]=gl.getUniformLocation(this.prog,name);
 gl.enable(gl.DEPTH_TEST);gl.depthFunc(gl.LEQUAL);gl.clearColor(.036,.042,.052,1);gl.disable(gl.CULL_FACE);gl.uniform1i(this.uniforms.u_baseTex,0);gl.uniform1i(this.uniforms.u_normalTex,1);gl.uniform1i(this.uniforms.u_mrTex,2);this.draws=[];this.textures=[];this.studio=.85;
 this.fallback=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,this.fallback);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,1,1,0,gl.RGBA,gl.UNSIGNED_BYTE,new Uint8Array([255,255,255,255]));gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);
 }
 async load(glb){const gl=this.gl,g=glb.json,views=new Map();this.glb=glb;
 const getView=(id,target)=>{const key=id+'_'+target;if(views.has(key))return views.get(key);const v=glb.view(id),b=gl.createBuffer();gl.bindBuffer(target,b);gl.bufferData(target,v,gl.STATIC_DRAW);views.set(key,b);return b};
 this.textures=[];
 for(const image of g.images||[]){if(image.bufferView===undefined)throw Error('External texture disallowed in offline GLB');const data=glb.view(image.bufferView);const bitmap=await createImageBitmap(new Blob([data],{type:image.mimeType||'image/png'}));const tex=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,tex);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,false);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,bitmap);bitmap.close();gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR_MIPMAP_LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.REPEAT);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.REPEAT);gl.generateMipmap(gl.TEXTURE_2D);this.textures.push(tex)}
 const attrSize={SCALAR:1,VEC2:2,VEC3:3,VEC4:4};this.draws=[];
 for(const node of g.nodes||[]){if(node.mesh===undefined)continue;const nodeMat=node.matrix?new Float32Array(node.matrix):matTRS(node.translation,node.rotation,node.scale);
 for(const primitive of g.meshes[node.mesh].primitives){if(primitive.mode!==undefined&&primitive.mode!==4)throw Error('Only glTF triangle primitives supported');const vao=gl.createVertexArray();gl.bindVertexArray(vao);
 for(const [name,slot] of [['POSITION',0],['NORMAL',1],['TEXCOORD_0',2]]){
  const aid=primitive.attributes[name];if(aid===undefined){gl.disableVertexAttribArray(slot);gl.vertexAttrib3f(slot,0,0,0);continue}
  const a=glb.accessor(aid),view=g.bufferViews[a.bufferView],buffer=getView(a.bufferView,gl.ARRAY_BUFFER);gl.bindBuffer(gl.ARRAY_BUFFER,buffer);
  const types={5126:gl.FLOAT,5123:gl.UNSIGNED_SHORT,5125:gl.UNSIGNED_INT,5121:gl.UNSIGNED_BYTE};if(!types[a.componentType])throw Error('Unsupported GLB accessor component');const bpc={5126:4,5123:2,5125:4,5121:1}[a.componentType];gl.enableVertexAttribArray(slot);gl.vertexAttribPointer(slot,attrSize[a.type],types[a.componentType],!!a.normalized,view.byteStride||attrSize[a.type]*bpc,a.byteOffset||0);
 }
 const idx=glb.accessor(primitive.indices),buf=getView(idx.bufferView,gl.ELEMENT_ARRAY_BUFFER);gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER,buf);const material=g.materials[primitive.material||0];this.draws.push({vao,nodeMat,count:idx.count,indexType:idx.componentType===5123?gl.UNSIGNED_SHORT:gl.UNSIGNED_INT,offset:idx.byteOffset||0,material});}
 }
 gl.bindVertexArray(null);return {drawCalls:this.draws.length,textures:this.textures.length};}
 materialTex(info){if(!info)return this.fallback;const texture=this.glb.json.textures[info.index];return this.textures[texture.source]||this.fallback}
 draw(q,height=0){const gl=this.gl,U=this.uniforms,g=this.glb;if(!g)return;const cw=this.canvas.width,ch=this.canvas.height;gl.viewport(0,0,cw,ch);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);gl.useProgram(this.prog);gl.uniformMatrix4fv(U.u_projection,false,perspective(Math.PI/3,cw/ch,.1,60));gl.uniformMatrix4fv(U.u_die,false,matTRS([0,height,-3.15],q,[1.22,1.22,1.22]));gl.uniform1f(U.u_studioStrength,this.studio);
 for(const item of this.draws){const mat=item.material,pbr=mat.pbrMetallicRoughness||{},base=pbr.baseColorFactor||[1,1,1,1];gl.uniformMatrix4fv(U.u_node,false,item.nodeMat);gl.uniform4fv(U.u_color,base);gl.uniform1f(U.u_roughness,pbr.roughnessFactor??1);gl.uniform1f(U.u_metallic,pbr.metallicFactor??1);gl.uniform1f(U.u_normalScale,mat.normalTexture?.scale??1);gl.uniform1i(U.u_hasBase,!!pbr.baseColorTexture?1:0);gl.uniform1i(U.u_hasNormal,!!mat.normalTexture?1:0);gl.uniform1i(U.u_hasMR,!!pbr.metallicRoughnessTexture?1:0);
 for(const [idx,src] of [pbr.baseColorTexture,mat.normalTexture,pbr.metallicRoughnessTexture].entries()){gl.activeTexture(gl.TEXTURE0+idx);gl.bindTexture(gl.TEXTURE_2D,this.materialTex(src))}gl.bindVertexArray(item.vao);gl.drawElements(gl.TRIANGLES,item.count,item.indexType,item.offset)}
 gl.bindVertexArray(null);}
}
root.DiceViewer={Viewer,matTRS,perspective,mul};if(typeof module!=='undefined'&&module.exports)module.exports=root.DiceViewer;
})(typeof window==='undefined'?globalThis:window);