#!/usr/bin/env nodejs

const fs = require('fs'); 
const bot = require("circle-github-bot").create();

fs.readdirSync("diffs")
	.filter(s=>s.match(".pdf$"))
	.map(s=>s.replace(".pdf",""))
	.forEach(file=> console.log(file))

const spawnSync = require( 'child_process' );
const ls = spawnSync.spawnSync( 'git', ["describe" ,"--always"]);

console.log( `git-commit: ${ls.stdout.toString()}` );

function addLink(file){
  text="";
  const diffFile = "diffs/"+file+".pdf";
  const fullFile = "pdfs/"+file+".pdf";
  console.log(file)
  console.log(diffFile)
  console.log(fullFile)

  text += ` ${bot.artifactLink(fullFile, file)}`;
  text += ` (${bot.artifactLink(diffFile, "diff")})`;
  return text;
}

if (fs.readdirSync("diffs").size==0) {
  return;
}


var text=`Changed PDFs as of ${ls.stdout.toString().trim()}:` 

text += fs.readdirSync("diffs")
	.filter(s=>s.match(".pdf$"))
	.map(s=>s.replace(".pdf",""))
	.map(file => addLink(file)).join(",")+".";


console.log(text)
bot.comment(text)