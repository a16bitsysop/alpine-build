#!/bin/sh

# called inside aport folder or first arg is dir to cd into
NME="builder"

[ -n "$1" ] && cd "$1"

if [ ! -f APKBUILD ]
then
  >&2 echo "No APKBUILD file to build"
  exit 2
fi

echo "Building ..."
echo "Arch is: $(uname -m)"
abuild -A
abuild -K -P /tmp/pkg
