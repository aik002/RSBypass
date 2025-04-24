set -e
RS_PATH="$(/usr/bin/env python3 `dirname $0`/FindRSPath.py)/steamapps/common/Rocksmith2014/Rocksmith2014.app/Contents/MacOS"
set +e

OSX_VERSION=$(sw_vers -productVersion | cut -d '.' -f 1,2)
ARCH=$(uname -m)
LEGACY_LINK="https://github.com/aik002/RSBypass/blob/main/LEGACY.md"
echo "OSX version:$OSX_VERSION / arch:$ARCH"

if (( $(echo "${OSX_VERSION} >= 14" | bc -l) )); then
    DYLIB_FOLDER=Sonoma
elif [ "$ARCH" == 'arm64' ]; then
    DYLIB_FOLDER=ARM
elif [ "$ARCH" == 'i386' ]; then
    DYLIB_FOLDER=x86
elif (( $(echo "${OSX_VERSION} < 10.14" | bc -l) )); then # Older than Monterey (12.0) 
    DYLIB_FOLDER=x64.Legacy
    echo "You are on an old architecture that might not work.  Please see $LEGACY_LINK for details"
else
    DYLIB_FOLDER=x64
fi
DYLIB="$DYLIB_FOLDER/libRSBypass.dylib"

echo "Selected folder: $DYLIB_FOLDER"

cd "`dirname "$0"`"
cp "$DYLIB" "$RS_PATH/"
./insert_dylib --inplace "$RS_PATH/libRSBypass.dylib" "$RS_PATH/Rocksmith2014"
