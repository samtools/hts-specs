#!/bin/sh
# Usage: rerun.sh FILEBASE LATEXCOMMAND ARGUMENT...
# Runs the LaTeX command as many times as necessary, as measured by
# the state files FILEBASE.aux etc having arrived at a steady state.

base=$1
shift

dir=$(dirname $base)
test -d $dir || mkdir $dir

# LaTeX always creates $base.aux. If it hasn't been run at all before,
# pre-seed with the expected "empty" contents that don't imply a rerun.
test -e $base.aux || printf '\\relax \n' > $base.aux

checksum_state_files() {
    for file in $base.*
    do
        case $file in
        *.log|*.pdf|*.ver) ;;
        *) cksum $file ;;
        esac
    done
}

prev=$(checksum_state_files)

"$@" || exit

checksum=$(checksum_state_files)

while test "$checksum" != "$prev"
do
    prev=$checksum

    echo '*' Rerunning $@
    "$@" || exit

    checksum=$(checksum_state_files)
done
