# Package

version       = "0.0.1"
author        = "ZyroX"
description   = "Tundra Interpreter"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["tundra"]
binDir        = "bin"


# Dependencies

requires "nim >= 2.2.2"
requires "cligen >= 1.7.3"
requires "nake >= 1.9.5"