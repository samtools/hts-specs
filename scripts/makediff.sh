#!/bin/bash

base_file=$1

merge_base=$(git merge-base HEAD origin/master)

latexdiff --version

echo <<EOF > config 
PICTUREENV=(?:picture|tikzpicture|DIFnomarkup)[\w\d*@]*
EOF

TEXINPUTS=:..:../new latexdiff-vc --pdf --dir=diffs -c config --graphics-markup=none -s ONLYCHANGEDPAGE  -t CULINECHBAR --ignore-warnings --force --git  -r $merge_base $base_file 