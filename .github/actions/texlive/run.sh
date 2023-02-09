#!/bin/sh

# This action runs inside a Docker container, running as a different Unix user
# from the owner of the checked-out files. Avoid Git's directory ownership
# security check by marking the repository directory as safe for Git, using
# a path reflecting where it is mounted within the container.
echo
echo Marking repository directory as Git-safe
echo "[command]git config --global --add safe.directory \"$GITHUB_WORKSPACE\""
git config --global --add safe.directory "$GITHUB_WORKSPACE" || exit

for cmd
do
    echo
    echo "[command]$cmd"
    eval "$cmd" || exit
done
