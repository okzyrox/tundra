## Builtins
const printfunc = proc(env: Environment, args: Value): Value =
  var output = ""
  if args.kind == vtArgs:
    for ix, item in args.argsValue:
      output &= $item
      if ix < args.argsValue.len - 1:
        output &= " "
  else:
    output = $args
  stdout.write(output)
  return Value(kind: vtNil)

const printlnfunc = proc(env: Environment, args: Value): Value =
  var output = ""
  if args.kind == vtArgs:
    for ix, item in args.argsValue:
      output &= $item
      if ix < args.argsValue.len - 1:
        output &= " "
  else:
    output = $args
  stdout.write(output & "\n")
  return Value(kind: vtNil)

const assertfunc = proc(env: Environment, args: Value): Value =
  if len(args.argsValue) < 1:
    raise newException(ValueError, "Invalid number of arguments")
  
  let condition = args.argsValue[0]
  if condition.kind != vtBool:
    raise newException(ValueError, "Invalid condition, boolean expected")

  if not condition.boolValue:
    let message = if len(args.argsValue) > 1: args.argsValue[1].stringValue else: "Assertion failed"
    raise newException(AssertionDefect, message)

  return Value(kind: vtNil)

const readfunc = proc(env: Environment, args: Value): Value =
  var message: string
  if len(args.argsValue) != 1:
    message = ""
  else:
    let value = args.argsValue[0]
    message = value.stringValue
  stdout.write(message)
  let input = readLine(stdin)
  return Value(kind: vtString, stringValue: input)

const readlnfunc = proc(env: Environment, args: Value): Value =
  var message: string
  if len(args.argsValue) != 1:
    message = ""
  else:
    let value = args.argsValue[0]
    message = value.stringValue
  stdout.write(message & "\n")
  let input = readLine(stdin)
  return Value(kind: vtString, stringValue: input)

const tostringfunc = proc(env: Environment, args: Value): Value =
  if len(args.argsValue) != 1:
    raise newException(ValueError, "Invalid number of arguments")
  try:
    let arg = args.argsValue[0]
    let argStr = $arg
    return Value(kind: vtString, stringValue: $argStr)
  except ValueError:
    raise newException(ValueError, "Invalid string value")

const tointfunc = proc(env: Environment, args: Value): Value =
  if len(args.argsValue) != 1:
    raise newException(ValueError, "Invalid number of arguments")
  let arg = args.argsValue[0]
  if arg.kind == vtInt:
    return arg
  elif arg.kind == vtFloat:
    return Value(kind: vtInt, intValue: int(arg.floatValue))
  elif arg.kind == vtString:
    let strValue = arg.stringValue
    try:
      let intValue = parseInt(strValue)
      return Value(kind: vtInt, intValue: intValue)
    except ValueError:
      raise newException(ValueError, "Could not convert string to int")
  else:
    raise newException(ValueError, "Invalid argument type for toint()")

const tofloatfunc = proc(env: Environment, args: Value): Value =
  if len(args.argsValue) != 1:
    raise newException(ValueError, "Invalid number of arguments")
  let arg = args.argsValue[0]
  if arg.kind == vtFloat:
    return arg
  elif arg.kind == vtInt:
    return Value(kind: vtFloat, floatValue: float(arg.intValue))
  elif arg.kind == vtString:
    let strValue = arg.stringValue
    try:
      let floatValue = parseFloat(strValue)
      return Value(kind: vtFloat, floatValue: floatValue)
    except ValueError:
      raise newException(ValueError, "Could not convert string to float")
  else:
    raise newException(ValueError, "Invalid argument type for tofloat()")

const tonumberfunc = proc(env: Environment, args: Value): Value =
  if len(args.argsValue) != 1:
    raise newException(ValueError, "Invalid number of arguments")
  let arg = args.argsValue[0]
  if arg.kind != vtString:
    raise newException(ValueError, "Invalid argument type for tonumber()")
  let strValue = arg.stringValue
  try:
    let intValue = parseInt(strValue)
    return Value(kind: vtInt, intValue: intValue)
  except ValueError:
    try:
      let floatValue = parseFloat(strValue)
      return Value(kind: vtFloat, floatValue: floatValue)
    except ValueError:
      raise newException(ValueError, "Could not convert string to number")

const typeoffunc = proc(env: Environment, args: Value): Value =
  if len(args.argsValue) != 1:
    raise newException(ValueError, "Invalid number of arguments")
  return Value(kind: vtString, stringValue: getValueType(args.argsValue[0]))

const lenfunc = proc(env: Environment, args: Value): Value = 
  if len(args.argsValue) != 1:
    raise newException(ValueError, "Invalid number of arguments")
  let arg = args.argsValue[0]
  if arg.kind == vtString:
    return Value(kind: vtInt, intValue: arg.stringValue.len)
  elif arg.kind == vtArray:
    return Value(kind: vtInt, intValue: arg.count)
  else:
    raise newException(ValueError, "Invalid argument type for `len()`")

const appendfunc = proc(env: Environment, args: Value): Value =
  if len(args.argsValue) != 2:
    raise newException(ValueError, "Invalid number of arguments")
  let arrayVal = args.argsValue[0]
  let elementVal = args.argsValue[1]
  if arrayVal.kind != vtArray:
    raise newException(ValueError, "Cannot append to something that is not an array")
  
  var elements = arrayVal.arrayValue
  elements.add(elementVal)
  
  var newVal = Value(
    kind: vtArray,
    arrayValue: elements,
    count: elements.len
  )

  env.set(arrayVal, newVal)

  return Value(kind: vtNil)

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
  interpreter.globals.define("tonumber", Value(kind: vtFunc, funcValue: tonumberfunc))
  interpreter.globals.define("toint", Value(kind: vtFunc, funcValue: tointfunc))
  interpreter.globals.define("tofloat", Value(kind: vtFunc, funcValue: tofloatfunc))

  # maths

  # array
  interpreter.globals.define("append", Value(kind: vtFunc, funcValue: appendfunc))

  # global vars
  interpreter.globals.define("_TUNDRA_VERSION", Value(kind: vtString, stringValue: utils.TUNDRA_VERSION))
  interpreter.globals.define("_TUNDRA_COMMIT", Value(kind: vtString, stringValue: utils.TUNDRA_COMMIT))

  interpreter.globals.define("globals", Value(kind: vtFunc, funcValue: proc(env: Environment, args: Value): Value =
    var table: Table[Value, Value]
    for key, value in interpreter.globals.values.pairs:
      let keyValue = Value(kind: vtString, stringValue: key)
      table[keyValue] = value
    return Value(kind: vtTable, tableValue: table)
  ))