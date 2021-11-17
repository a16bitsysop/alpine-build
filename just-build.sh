#!/bin/sh

# called inside aport folder
NME="builder"

if [ ! -f APKBUILD ]
then
  >&2 echo "No APKBUILD file to build"
  exit 2
fi

echo "Building ..."
echo "Arch is: $(uname -m)"
cd /tmp
abuild checksum
abuild -A
abuild -rK

APKS=$(find /home/"$NME"/packages -name APKINDEX.tar.gz | wc -l)
if [ "$APKS" -lt 1 ]
then
  echo "no apks built, exiting"
  exit 1
fi

echo "Copying Packages"
mkdir -p packages/"$(uname -m)"
cp -a /home/"$NME"/packages/* packages/"$(uname -m)"
