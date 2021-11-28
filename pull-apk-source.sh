#!/bin/sh

[ -z "$1" ] && echo "needs aport eg $0 community/rspamd" && exit 1

AGIT="https://github.com/alpinelinux/aports"
TNME="tmp_aports"

git clone "$AGIT" --depth 1 \
  --filter=blob:none \
  --sparse "$TNME" && \
  (cd "$TNME" && \
   git sparse-checkout add "$1" && \
   git checkout)

mv tmp_aports/"$1" $(basename "$1")

rm -rf "$TNME"
