RS_PATH="/Users/$USER/Library/Application Support/Steam/steamapps/common/Rocksmith2014/Rocksmith2014.app/Contents/MacOS"
OSX_VERSION=$(sw_vers -productVersion | cut -d '.' -f 1,2)
ARCH=$(uname -m)
echo "OSX version:$OSX_VERSION / arch:$ARCH"

if test "$ARCH" = 'arm64'; then
    DYLIB_FOLDER=ARM
elif test "$ARCH" = 'i386'; then
    DYLIB_FOLDER=x86
elif [ 1 -eq "$(echo "${OSX_VERSION} < 10.14" | bc -l)" ]; then # Older than Monterey (12.0) 
    DYLIB_FOLDER=x64.Legacy
else
    DYLIB_FOLDER=x64
fi
DYLIB="$DYLIB_FOLDER/libRSBypass.dylib"

cd "`dirname "$0"`"
cp "$DYLIB" "$RS_PATH/"
./insert_dylib --inplace "$RS_PATH/libRSBypass.dylib" "$RS_PATH/Rocksmith2014"
