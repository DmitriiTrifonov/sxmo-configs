#!/bin/sh
# Restore sxmo configs into $HOME. Existing files are kept as *.orig
set -e
SRC="$(cd "$(dirname "$0")" && pwd)/files"
cd "$SRC"
find . -type f | while read -r f; do
  dst="$HOME/${f#./}"
  mkdir -p "$(dirname "$dst")"
  [ -e "$dst" ] && ! cmp -s "$f" "$dst" && cp -a "$dst" "$dst.orig"
  cp -a "$f" "$dst"
  echo "restored $dst"
done
# SXMO_BG_IMG in .config/sxmo/profile is an absolute path; fix it if the user/home differs
sed -i "s|/home/[^/]*/wallpaper|$HOME/wallpaper|" "$HOME/.config/sxmo/profile"
echo "Done. Restart sxmo (or sxmo_hook_... reload) to apply."
