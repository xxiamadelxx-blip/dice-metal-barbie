'use strict';
const fs=require('node:fs'),path=require('node:path'),Module=require('node:module');
module.exports=function loadSource(relativePath){
 const filename=path.resolve(__dirname,relativePath),instance=new Module(filename,module);
 instance.filename=filename;
 instance.paths=Module._nodeModulePaths(__dirname);
 instance._compile(fs.readFileSync(filename,'utf8'),filename);
 return instance.exports;
};
