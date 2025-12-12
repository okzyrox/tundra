## utils
##

const DEBUG = false

const TUNDRA_VERSION* {.strdefine.}: string = "0.0.1-alpha"
const TUNDRA_COMMIT* {.strdefine.}: string = "0"

proc print*(str: string) =
  if DEBUG:
    echo(str)

proc print*(things: varargs[string, `$`]) =
  if DEBUG:
    var stat: string
    for thing in things:
      stat = stat & thing
    echo stat
