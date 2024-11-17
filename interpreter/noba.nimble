# Package

version       = "0.0.1"
author        = "ZyroX"
description   = "nb-interpreter"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["nb"]
binDir        = "../bin"


# Dependencies

requires "nim >= 2.0.0"
requires "cligen >= 1.7.3"