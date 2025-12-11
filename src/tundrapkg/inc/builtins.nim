## Builtins
const printfunc = proc(args: Value): Value =
  var output = ""
  if args.kind == vtArgs:
    for ix, item in args.argsValue:
      output &= $item
      if ix < args.argsValue.len - 1:
        output &= ", "
  else:
    output = $args
  stdout.write(output)
  return Value(kind: vtNil)

const printlnfunc = proc(args: Value): Value =
  var output = ""
  if args.kind == vtArgs:
    for ix, item in args.argsValue:
      output &= $item
      if ix < args.argsValue.len - 1:
        output &= ", "
  else:
    output = $args
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
    raise newException(AssertionDefect, message)

  return Value(kind: vtNil)

const readfunc = proc(args: Value): Value =
  let message = args.argsValue[0]
  stdout.write(message.stringValue)
  let input = readLine(stdin)
  return Value(kind: vtString, stringValue: input)

const readlnfunc = proc(args: Value): Value =
  if len(args.argsValue) != 1:
    raise newException(ValueError, "Invalid number of arguments")
  let message = args.argsValue[0]
  stdout.write(message.stringValue & "\n")
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
    elif arg.kind == vtBool:
      return Value(kind: vtString, stringValue: $arg.boolValue)
    elif arg.kind == vtNil:
      return Value(kind: vtString, stringValue: "nil")
    else:
      raise newException(ValueError, "Invalid string value")
  except ValueError:
    raise newException(ValueError, "Invalid string value")

const typeoffunc = proc(args: Value): Value =
  if len(args.argsValue) != 1:
    raise newException(ValueError, "Invalid number of arguments")
  return Value(kind: vtString, stringValue: getValueType(args.argsValue[0]))

const lenfunc = proc(args: Value): Value = 
  if len(args.argsValue) != 1:
    raise newException(ValueError, "Invalid number of arguments")
  let arg = args.argsValue[0]
  if arg.kind == vtString:
    # probably should sort out the quotes stuff
    # i mean its fine for now and asserts work cause of it but still...
    return Value(kind: vtInt, intValue: arg.stringValue.len)
  else:
    raise newException(ValueError, "Invalid argument type for `len()`")

# const keysfunc = proc(args: Value): Value =
#   if len(args.argsValue) != 1:
#     raise newException(ValueError, "Invalid num of arguments for keys()")
  
#   let arg = args.argsValue[0]
#   if arg.kind != vtTable:
#     raise newException(ValueError, "Cannot get keys of a non-table value")
  
#   var keys: seq[Value] = @[]
#   for key in arg.tableValue.keys:
#     keys.add(key)
  
#   return Value(kind: vtArgs, argsValue: keys)

proc initializeGlobals*(interpreter: Interpreter) =
  interpreter.globals.define("print", Value(kind: vtFunc, funcValue: printfunc)) ## no new line
  interpreter.globals.define("println", Value(kind: vtFunc, funcValue: printlnfunc))
  interpreter.globals.define("read", Value(kind: vtFunc, funcValue: readfunc)) ## same line read
  interpreter.globals.define("readln", Value(kind: vtFunc, funcValue: readlnfunc)) ## new line read
  interpreter.globals.define("assert", Value(kind: vtFunc, funcValue: assertfunc)) 
  interpreter.globals.define("typeof", Value(kind: vtFunc, funcValue: typeoffunc)) ## get type of value
  interpreter.globals.define("len", Value(kind: vtFunc, funcValue: lenfunc))

  # conversions
  interpreter.globals.define("tostring", Value(kind: vtFunc, funcValue: tostringfunc))