## The interpreter
##

import ast, utils
import tables, strutils, options

type
  ValueType = enum
    vtFunc, vtInt, vtFloat, vtString, vtBool, vtNil

  Value = object
    case kind: ValueType
    of vtInt: intValue: int
    of vtFloat: floatValue: float
    of vtString: stringValue: string
    of vtBool: boolValue: bool
    of vtFunc: funcValue: proc(args: seq[Value]): Value
    of vtNil: discard

  Environment = ref object
    values: Table[string, Value]
    parent: Environment

  Interpreter = ref object
    globals: Environment
    environment: Environment

proc newEnvironment(parent: Environment = nil): Environment =
  Environment(values: initTable[string, Value](), parent: parent)

proc newInterpreter*(): Interpreter =
  let globals = newEnvironment()
  new(result)
  result.globals = globals
  result.environment = globals

proc define(env: Environment, name: string, value: Value) =
  env.values[name] = value

proc get(env: Environment, name: string): Value =
  if env.values.hasKey(name):
    return env.values[name]
  elif env.parent != nil:
    return env.parent.get(name)
  else:
    raise newException(ValueError, "Undefined variable '" & name & "'")

proc getAll*(interpreter: Interpreter): seq[string] =
  for key, val in interpreter.environment.values:
    result.add(key)


proc set(env: Environment, name: string, value: Value) =
  if env.values.hasKey(name):
    env.values[name] = value
  elif env.parent != nil:
    env.parent.set(name, value)
  else:
    raise newException(ValueError, "Undefined variable '" & name & "'")

proc evaluate(interpreter: Interpreter, node: Node): Value

proc evaluateLiteral(interpreter: Interpreter, node: Node): Value =
  case node.literalType
  of "int":
    Value(kind: vtInt, intValue: parseInt(node.literalValue))
  of "float":
    Value(kind: vtFloat, floatValue: parseFloat(node.literalValue))
  of "string":
    Value(kind: vtString, stringValue: node.literalValue)
  of "bool":
    Value(kind: vtBool, boolValue: parseBool(node.literalValue))
  else:
    Value(kind: vtNil)

proc evaluateIdentifier(interpreter: Interpreter, node: Node): Value =
  interpreter.environment.get(node.identifierName)

proc evaluateBinaryExpr(interpreter: Interpreter, node: Node): Value =
  let left = interpreter.evaluate(node.left)
  let right = interpreter.evaluate(node.right)

  case node.operator
  of "+":
    case left.kind
    of vtInt:
      if right.kind == vtInt:
        return Value(kind: vtInt, intValue: left.intValue + right.intValue)
    of vtFloat:
      if right.kind == vtFloat:
        return Value(kind: vtFloat, floatValue: left.floatValue +
            right.floatValue)
    of vtString:
      if right.kind == vtString:
        return Value(kind: vtString, stringValue: left.stringValue &
            right.stringValue)
    else:
      discard

  raise newException(ValueError, "Invalid operator for types")

proc evaluateVarDecl(interpreter: Interpreter, node: Node) =
  let value = interpreter.evaluate(node.value)
  interpreter.environment.define(node.name, value)
  print "Defined variable: ", node.name, " with value: ", value

proc evaluateFuncDecl(interpreter: Interpreter, node: Node) =
  let function = proc(args: seq[Value]): Value =
    let prevEnv = interpreter.environment
    interpreter.environment = newEnvironment(prevEnv)
    for i, param in node.params:
      if i < args.len:
        interpreter.environment.define(param.name, args[i])
      else:
        interpreter.environment.define(param.name, Value(kind: vtNil))
    var result = Value(kind: vtNil)
    for stmt in node.body:
      result = interpreter.evaluate(stmt)
    interpreter.environment = prevEnv
    return result
  interpreter.environment.define(node.fnName, Value(kind: vtFunc, funcValue: function))

proc evaluateUnaryExpr(interpreter: Interpreter, node: Node): Value =
  let operand = interpreter.evaluate(node.operand)
  case node.unaryOperator
  of "-":
    case operand.kind
    of vtInt: return Value(kind: vtInt, intValue: -operand.intValue)
    of vtFloat: return Value(kind: vtFloat, floatValue: -operand.floatValue)
    else: raise newException(ValueError, "Invalid operand for minus")
  of "!":
    case operand.kind
    of vtBool: return Value(kind: vtBool, boolValue: not operand.boolValue)
    else: raise newException(ValueError, "Invalid operand for logical not")
  else:
    raise newException(ValueError, "Unknown unary operator: " &
        node.unaryOperator)

proc evaluateConstDecl(interpreter: Interpreter, node: Node) =
  let value = interpreter.evaluate(node.value)
  interpreter.environment.define(node.name, value)
  # Unfinished

proc evaluateIfStmt(interpreter: Interpreter, node: Node): Value =
  let condition = interpreter.evaluate(node.condition)
  if condition.kind != vtBool:
    raise newException(ValueError, "If condition must be a boolean")
  if condition.boolValue:
    for stmt in node.thenBranch:
      result = interpreter.evaluate(stmt)
  elif node.elseBranch.len > 0:
    for stmt in node.elseBranch:
      result = interpreter.evaluate(stmt)
  else:
    result = Value(kind: vtNil)

proc evaluateWhileStmt(interpreter: Interpreter, node: Node): Value =
  while true:
    let condition = interpreter.evaluate(node.loopCondition)
    if condition.kind != vtBool:
      raise newException(ValueError, "While condition must be a boolean")
    if not condition.boolValue:
      break
    for stmt in node.loopBody:
      discard interpreter.evaluate(stmt)
  return Value(kind: vtNil)

proc evaluateForStmt(interpreter: Interpreter, node: Node): Value =
  raise newException(ValueError, "For loop not implemented yet")

proc evaluateReturnStmt(interpreter: Interpreter, node: Node): Value =
  return interpreter.evaluate(node.returnValue)

proc evaluateCall(interpreter: Interpreter, node: Node): Value =
  let callee = interpreter.evaluate(node.callee)
  var arguments: seq[Value] = @[]
  for arg in node.arguments:
    arguments.add(interpreter.evaluate(arg))
  
  if callee.kind != vtFunc:
    raise newException(ValueError, "Can only call functions.")
  
  return callee.funcValue(arguments)

proc evaluate(interpreter: Interpreter, node: Node): Value =
  print "evaluating ", node.kind
  case node.kind
  of nkProgram:
    var lastValue = Value(kind: vtNil)
    for statement in node.statements:
      lastValue = interpreter.evaluate(statement)
    return lastValue
  of nkLiteral:
    return interpreter.evaluateLiteral(node)
  of nkIdentifier:
    return interpreter.evaluateIdentifier(node)
  of nkBinaryExpr:
    return interpreter.evaluateBinaryExpr(node)
  of nkUnaryExpr:
    return interpreter.evaluateUnaryExpr(node)
  of nkVarDecl:
    interpreter.evaluateVarDecl(node)
    return Value(kind: vtNil)
  of nkConstDecl:
    interpreter.evaluateConstDecl(node)
    return Value(kind: vtNil)
  of nkFunctionDecl:
    interpreter.evaluateFuncDecl(node)
    return Value(kind: vtNil)
  of nkIfStmt:
    return interpreter.evaluateIfStmt(node)
  of nkWhileStmt:
    return interpreter.evaluateWhileStmt(node)
  of nkForStmt:
    return interpreter.evaluateForStmt(node)
  of nkReturnStmt:
    return interpreter.evaluateReturnStmt(node)
  of nkExprStmt:
    return interpreter.evaluate(node.expr)
  of nkCall:
    return interpreter.evaluateCall(node)
  else:
    raise newException(ValueError, "Unexpected node type: " & $node.kind)

## Builtins

const println = proc(args: seq[Value]): Value =
  echo "println"
  for arg in args:
    case arg.kind
    of vtInt: stdout.write($arg.intValue)
    of vtFloat: stdout.write($arg.floatValue)
    of vtString: stdout.write(arg.stringValue)
    of vtBool: stdout.write($arg.boolValue)
    of vtFunc: stdout.write("Function")
    of vtNil: stdout.write("nil")
  echo ""
  Value(kind: vtNil)

proc initializeGlobals*(interpreter: Interpreter) =
  let println = proc(args: seq[Value]): Value =
    for arg in args:
      case arg.kind
      of vtInt: stdout.write($arg.intValue)
      of vtFloat: stdout.write($arg.floatValue)
      of vtString: stdout.write(arg.stringValue)
      of vtBool: stdout.write($arg.boolValue)
      of vtNil: stdout.write("nil")
      of vtFunc: stdout.write("<function>")
    echo ""
    return Value(kind: vtNil)

  interpreter.globals.define("println", Value(kind: vtFunc, funcValue: println))

proc findMainFunction(interpreter: Interpreter): Option[Value] =
  if interpreter.globals.values.hasKey("main"):
    let mainValue = interpreter.globals.values["main"]
    if mainValue.kind == vtFunc:
      return some(mainValue)
  return none(Value)


## int
##
proc interpret*(interpreter: Interpreter, node: Node) =
  print("interpreting")
  discard interpreter.evaluate(node)

  # Attempts to find a main function if it exists, otherwise we bail for now
  let mainFunc = interpreter.findMainFunction()
  if mainFunc.isSome:
    echo("Calling main function")
    discard interpreter.evaluateCall(Node(kind: nkCall, callee: Node(
        kind: nkIdentifier, identifierName: "main"), arguments: @[]))
  else:
    echo("No main function found")
