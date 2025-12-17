## utils
##

const TUNDRA_VERSION* {.strdefine.}: string = "0.0.1-alpha"
const TUNDRA_COMMIT* {.strdefine.}: string = "0"

const DEBUG_LOGGING {.booldefine.}: bool = false

proc print*(str: string) =
  if DEBUG_LOGGING:
    echo(str)

proc print*(things: varargs[string, `$`]) =
  if DEBUG_LOGGING:
    var stat: string
    for thing in things:
      stat = stat & thing
    echo stat
