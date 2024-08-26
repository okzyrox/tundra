# Package

version       = "0.0.1"
author        = "ZyroX"
description   = "nb-interpreter"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["noba"]
binDir        = "build"


# Dependencies

requires "nim >= 2.0.8"
requires "cligen >= 1.7.3"