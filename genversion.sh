#!/bin/sh

# Add "-dirty" only if any of *this* PDF's source files is dirty
test -n "$(git status --porcelain "$@")" && dirty=-dirty

git rev-list -n1 --format='date %cD' HEAD -- "$@" | while read key value
do
    case $key in
    commit)
        value=$(git describe --always $value)
        echo "@newcommand*@commitdesc{$value$dirty}"
        ;;
    date)
        # Cut unwanted fields from "[Day, ]DD Mon YYYY[ HH:MM:SS +ZZZZ]"
        value=$(echo $value | sed 's/.*, *//;s/ *[0-9]*:.*//')
        echo "@newcommand*@headdate{$value}"
        ;;
    esac
done | tr @ \\
