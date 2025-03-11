## Builtins
import strutils, sequtils

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
  if len(args.argsValue) < 1:
    raise newException(ValueError, "Invalid number of arguments")
  
  let condition = args.argsValue[0]
  if condition.kind != vtBool:
    raise newException(ValueError, "Invalid condition, boolean expected")

  if not condition.boolValue:
    let message = if len(args.argsValue) > 1: args.argsValue[1].stringValue else: "Assertion failed"
    raise newException(AssertionError, message)

  return Value(kind: vtNil)

const readfunc = proc(args: Value): Value =
  let message = args.argsValue[0]
  stdout.write(message.stringValue.strip(leading = true, trailing = true, chars = {'\"'}))
  let input = readLine(stdin)
  return Value(kind: vtString, stringValue: input)

const readlnfunc = proc(args: Value): Value =
  if len(args.argsValue) != 1:
    raise newException(ValueError, "Invalid number of arguments")
  let message = args.argsValue[0]
  stdout.write(message.stringValue.strip(leading = true, trailing = true, chars = {'\"'}) & "\n")
  let input = readLine(stdin)
  return Value(kind: vtString, stringValue: input)

const tostringfunc = proc(args: Value): Value =
  if len(args.argsValue) != 1:
    raise newException(ValueError, "Invalid number of arguments")
  try:
    let arg = args.argsValue[0]
    if arg.kind == vtInt:
      return Value(kind: vtString, stringValue: $arg.intValue)
    elif arg.kind == vtFloat:
      return Value(kind: vtString, stringValue: $arg.floatValue)
    elif arg.kind == vtString:
      return Value(kind: vtString, stringValue: arg.stringValue)
    else:
      raise newException(ValueError, "Invalid string value")
  except ValueError:
    raise newException(ValueError, "Invalid string value")

const typeoffunc = proc(args: Value): Value =
  if len(args.argsValue) != 1:
    raise newException(ValueError, "Invalid number of arguments")
  return Value(kind: vtString, stringValue: getValueType(args.argsValue[0]))

proc initializeGlobals*(interpreter: Interpreter) =
  interpreter.globals.define("print", Value(kind: vtFunc, funcValue: printfunc)) ## no new line
  interpreter.globals.define("println", Value(kind: vtFunc, funcValue: printlnfunc))
  interpreter.globals.define("read", Value(kind: vtFunc, funcValue: readfunc)) ## same line read
  interpreter.globals.define("readln", Value(kind: vtFunc, funcValue: readlnfunc)) ## new line read
  interpreter.globals.define("assert", Value(kind: vtFunc, funcValue: assertfunc)) 
  interpreter.globals.define("typeof", Value(kind: vtFunc, funcValue: typeoffunc)) ## get type of value

  # conversions
  interpreter.globals.define("tostring", Value(kind: vtFunc, funcValue: tostringfunc))