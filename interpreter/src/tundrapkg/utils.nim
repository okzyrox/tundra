## utils
##


const DEBUG = false

proc print*(str: string) =
  if DEBUG:
    echo(str)


proc print*(things: varargs[string, `$`]) =
  if DEBUG:
    var stat: string
    for thing in things:
      stat = stat & thing
    echo stat
