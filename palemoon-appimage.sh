#!/bin/sh

set -ex

export ARCH=$(uname -m)
APPIMAGETOOL="https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
export URUNTIME_PRELOAD=1 # really needed here

DESKTOP="https://repo.palemoon.org/MoonchildProductions/Pale-Moon/raw/branch/master/palemoon/branding/official/palemoon.desktop"
ICON="https://repo.palemoon.org/MoonchildProductions/Pale-Moon/raw/branch/master/palemoon/branding/official/default256.png"

tarball_url=https://rm-us.palemoon.org/release/$(wget https://www.palemoon.org/download.shtml -O - \
	| sed 's/[()",{}]/ /g; s/ /\n/g' | grep -i "linux-$ARCH-.*.tar.xz" | grep -vi "gtk2" | head -1)

export VERSION=$(echo "$tarball_url" | awk -F'/' '{print $NF; exit}' \
	| awk -F'-' '{print $2}' | sed 's|.linux.*||')
echo "$VERSION" > ~/version

wget "$tarball_url" -O ./package.tar.xz
tar xvf ./package.tar.xz
rm -f ./package.tar.xz

mv -v ./palemoon ./AppDir && (
	cd ./AppDir
	wget "$ICON"    -O  ./palemoon.png
	wget "$ICON"    -O  ./.DirIcon
	wget "$DESKTOP" -O  ./palemoon.desktop

	cat > ./AppRun <<- 'KEK'
	#!/bin/sh
	CURRENTDIR="$(cd "${0%/*}" && echo "$PWD")"
	export PATH="${CURRENTDIR}:${PATH}"
	export MOZ_LEGACY_PROFILES=1          # Prevent per installation profiles
	export MOZ_APP_LAUNCHER="${APPIMAGE}" # Allows setting as default browser
	exec "${CURRENTDIR}/palemoon" "$@"
	KEK
	chmod +x ./AppRun

	# disable automatic updates
	mkdir -p ./distribution
	cat >> ./distribution/policies.json <<- 'KEK'
	{
	  "policies": {
	    "DisableAppUpdate": true,
	    "AppAutoUpdate": false,
	    "BackgroundAppUpdate": false
	  }
	}
	KEK
)

wget "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool
./appimagetool -n -u "$UPINFO" ./AppDir
