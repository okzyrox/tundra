## Builtins


const printfunc = proc(args: Value): Value =
  var output = ""
  if args.kind == vtArgs:
    output = args.argsValue.mapIt($it).join(", ")
  else:
    output = $args
  output = output.strip(leading = true, trailing = true, chars = {'\"'})
  stdout.write(output)
  return Value(kind: vtNil)

const printlnfunc = proc(args: Value): Value =
  var output = ""
  if args.kind == vtArgs:
    output = args.argsValue.mapIt($it).join(", ")
  else:
    output = $args
  output = output.strip(leading = true, trailing = true, chars = {'\"'})
  stdout.write(output & "\n")
  return Value(kind: vtNil)

const assertfunc = proc(args: Value): Value =
  let condition = args.argsValue[0]
  let expected = args.argsValue[1]
  let message = args.argsValue[2]
  if condition != expected:
    raise newException(ValueError, message.stringValue)

  return Value(kind: vtNil)

const readfunc = proc(args: Value): Value =
  let message = args.argsValue[0]
  stdout.write(message.stringValue.strip(leading = true, trailing = true, chars = {'\"'}))
  let input = readLine(stdin)
  return Value(kind: vtString, stringValue: input)

const readlnfunc = proc(args: Value): Value =
  let message = args.argsValue[0]
  stdout.write(message.stringValue.strip(leading = true, trailing = true, chars = {'\"'}) & "\n")
  let input = readLine(stdin)
  return Value(kind: vtString, stringValue: input)

proc initializeGlobals*(interpreter: Interpreter) =
  interpreter.globals.define("print", Value(kind: vtFunc, funcValue: printfunc)) ## no new line
  interpreter.globals.define("println", Value(kind: vtFunc, funcValue: printlnfunc))
  interpreter.globals.define("read", Value(kind: vtFunc, funcValue: readfunc)) ## same line read
  interpreter.globals.define("readln", Value(kind: vtFunc, funcValue: readlnfunc)) ## new line read
  interpreter.globals.define("assert", Value(kind: vtFunc, funcValue: assertfunc)) 