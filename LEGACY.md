# Legacy Support

## Patch fails with errors

### Build errors

You get errors from the patch that look like this:

```
OSX version:10.13 / arch:x86_64
Binary is a fat binary with 2 archs.
dyld: lazy symbol binding failed: Symbol not found: ____chkstk_darwin
  Referenced from: /Users/myusername/Downloads/rsbypass/RSBypass/./insert_dylib (which was built for Mac OS X 12.0)
  Expected in: /usr/lib/libSystem.B.dylib

dyld: Symbol not found: ____chkstk_darwin
  Referenced from: /Users/myusername/Downloads/rsbypass/RSBypass/./insert_dylib (which was built for Mac OS X 12.0)
  Expected in: /usr/lib/libSystem.B.dylib
```

If you're getting this error, it means that the patch was built for a newer
version of OSX and will not run on your machine as is.

You can try running the old patch, found here:
https://github.com/aik002/RSBypass/raw/main/Legacy_Patch.zip
