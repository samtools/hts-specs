#!/usr/bin/env nodejs

const bot = require("circle-github-bot").create();
const fs = require('fs');

const spawnSync = require( 'child_process' );
const ls = spawnSync.spawnSync( 'git', ["describe" ,"--always"]);

function addLink(file){
  text="";
  const diffFile = "diff/"+file+".pdf";
  const fullFile = "pdfs/"+file+".pdf";
  console.log(file)
  console.log(diffFile)
  console.log(fullFile)

  text += ` ${bot.artifactLink(fullFile, file)}`;
  return text;
}

console.log( `git-commit: ${ls.stdout.toString()}` );

const diffPDFs = fs.readdirSync("diff")
  .filter(s=>s.match(".pdf$"));

if (diffPDFs.length==0) {
  console.log("No diffs.")
}

diffPDFs.map(s=>s.replace(".pdf",""))
  .forEach(file=> console.log(file))

var text=`Changed PDFs as of ${ls.stdout.toString().trim()}:`

text += fs.readdirSync("diff")
	.filter(s=>s.match(".pdf$"))
	.map(s=>s.replace(".pdf",""))
	.map(file => addLink(file)).join(",")+".";

text += addLink("crypt4gh");

console.log(text)
bot.comment(process.env.GH_AUTH_TOKEN, text)
