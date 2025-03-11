## The interpreter
##

import ast, utils
import tables, strutils, options, sequtils

type
  ValueType = enum
    vtFunc, vtInt, vtFloat, vtString, vtBool, vtNil, vtArgs, vtOperator

  Value = object
    case kind: ValueType
    of vtInt: intValue: int
    of vtFloat: floatValue: float
    of vtString: stringValue: string
    of vtBool: boolValue: bool
    of vtFunc: funcValue: proc(args: Value): Value
    of vtOperator: binaryExpr: Node
    of vtArgs: argsValue: seq[Value]
    of vtNil: discard

  Environment = ref object
    values: Table[string, Value]
    parent: Environment

  Interpreter = ref object
    globals: Environment
    environment: Environment
    functionDeclarations*: Table[string, Node] # used for type checking and whatnot

proc `==`(a, b: Value): bool =
  if a.kind != b.kind:
    return false
  
  var kind = a.kind
  case kind
  of vtInt:
    if b.kind != vtInt:
      return false
    return a.intValue == b.intValue
  of vtFloat:
    if b.kind != vtFloat:
      return false
    return a.floatValue == b.floatValue
  of vtString:
    if b.kind != vtString:
      return false
    return a.stringValue == b.stringValue
  of vtBool:
    if b.kind != vtBool:
      return false
    return a.boolValue == b.boolValue
  else:
    return false

proc `!=`(a, b: Value): bool =
  not (a == b)
  
proc getValueType(value: Value): string =
  case value.kind
  of vtInt: return "int"
  of vtFloat: return "float"
  of vtString: return "string"
  of vtBool: return "bool"
  of vtNil: return "nil"
  of vtFunc: return "function"
  else: return "unknown"

proc newEnvironment(parent: Environment = nil): Environment =
  Environment(values: initTable[string, Value](), parent: parent)

proc newInterpreter*(): Interpreter =
  let globals = newEnvironment()
  new(result)
  result.globals = globals
  result.environment = globals
  result.functionDeclarations = initTable[string, Node]()

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
  of "operator":
    Value(kind: vtString, stringValue: node.literalValue)
  else:
    Value(kind: vtNil)

proc `$`(v: Value): string =
  case v.kind
  of vtInt: $v.intValue
  of vtFloat: $v.floatValue
  of vtString: v.stringValue
  of vtBool: $v.boolValue
  of vtFunc: "<function>"
  of vtArgs: 
    var output: seq[string] = @[]
    for arg in v.argsValue:
      output.add($arg)
    output.join(" ")
  of vtNil: "nil"
  else:
    "other value kind"

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
        return Value(kind: vtFloat, floatValue: left.floatValue + right.floatValue)
    of vtString:
      var val: string
      var left = left.stringValue
      var right = 
        if right.kind == vtString:
          right.stringValue
        else:
          $right & "\""
      left = left.strip(leading = false, trailing = true, chars = {'\"'})
      right = right.strip(leading = true, trailing = false, chars = {'\"'})
      val = left & right
      return Value(kind: vtString, stringValue: val)
    else:
      discard
  of "-":
    case left.kind
    of vtInt:
      if right.kind == vtInt:
        print "Subtracting integers: ", left.intValue, " - ", right.intValue
        return Value(kind: vtInt, intValue: left.intValue - right.intValue)
    of vtFloat:
      if right.kind == vtFloat:
        print "Subtracting floats: ", left.floatValue, " - ", right.floatValue
        return Value(kind: vtFloat, floatValue: left.floatValue - right.floatValue)
    else:
      discard
  of "*":
    case left.kind
    of vtInt:
      if right.kind == vtInt:
        return Value(kind: vtInt, intValue: left.intValue * right.intValue)
    of vtFloat:
      if right.kind == vtFloat:
        return Value(kind: vtFloat, floatValue: left.floatValue * right.floatValue)
    else:
      discard
  of "/":
    case left.kind
    of vtInt:
      if right.kind == vtInt:
        var value = left.intValue / right.intValue
        return Value(kind: vtFloat, floatValue: value)
    of vtFloat:
      if right.kind == vtFloat:
        return Value(kind: vtFloat, floatValue: left.floatValue / right.floatValue)
    else:
      discard
  of "%":
    case left.kind
    of vtInt:
      if right.kind == vtInt:
        return Value(kind: vtInt, intValue: left.intValue mod right.intValue)
      else:
        discard
    else:
      discard
  of "==":
    return Value(kind: vtBool, boolValue: left == right)
  of "!=":
    return Value(kind: vtBool, boolValue: left != right)
  of ",":
    return Value(kind: vtArgs, argsValue: @[left, right])

  raise newException(ValueError, "Invalid operator for types " & 
    getValueType(left) & " and " & getValueType(right) & "are not compatible with " & node.operator)

proc evaluateVarDecl(interpreter: Interpreter, node: Node): Value =
  let value = interpreter.evaluate(node.value)
  interpreter.environment.define(node.name, value)
  print "Defined variable: ", node.name, " with value: ", value
  return value

proc evaluateFuncDecl(interpreter: Interpreter, node: Node) =
  let function = proc(args: Value): Value =
    let prevEnv = interpreter.environment
    interpreter.environment = newEnvironment(if prevEnv.parent != nil: prevEnv.parent else: interpreter.globals)
    for i, param in node.params:
      if i < args.argsValue.len:
        interpreter.environment.define(param.name, args.argsValue[i])
    
    result = Value(kind: vtNil)
    for stmt in node.body:
      result = interpreter.evaluate(stmt)
      if stmt.kind == nkReturnStmt:
        interpreter.environment = prevEnv
        return result
    
    interpreter.environment = prevEnv
    return result

  interpreter.environment.define(node.fnName, Value(kind: vtFunc, funcValue: function))
  interpreter.functionDeclarations[node.fnName] = node

proc evaluateUnaryExpr(interpreter: Interpreter, node: Node): Value =
  let operand = interpreter.evaluate(node.operand)
  case node.unaryOperator
  of "+":
    case operand.kind
    of vtInt: return Value(kind: vtInt, intValue: +operand.intValue)
    of vtFloat: return Value(kind: vtFloat, floatValue: +operand.floatValue)
    else: raise newException(ValueError, "Invalid operand for plus")
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
  let callee = interpreter.evaluate(node.callee) # whatever we're trying to call
  var arguments: Value = Value(kind: vtArgs, argsValue: @[]) # arguments to pass to the callee
  
  var funcName = ""
  if node.callee.kind == nkIdentifier:
    funcName = node.callee.identifierName
  
  for arg in node.arguments:
    arguments.argsValue.add(interpreter.evaluate(arg))
  
  if callee.kind != vtFunc:
    raise newException(ValueError, "Can only call functions.")
  
  if funcName != "":
    # todo: give interpreter knowledge of builtins available
    for fn in ["println", "print", "assert", "read", "readln"]:
      if funcName == fn:
        return callee.funcValue(arguments)
    
    for stmt in interpreter.globals.values.keys:
      if stmt == funcName:
        let funcVal = interpreter.globals.values[stmt]
        if funcVal.kind == vtFunc:
          var fnDecl = interpreter.functionDeclarations.getOrDefault(funcName)
          if fnDecl != nil:
            # check invalid argument count
            if fnDecl.params.len != arguments.argsValue.len:
              raise newException(ValueError, "Function '" & funcName & "' expects " & 
                $fnDecl.params.len & " arguments, got " & $arguments.argsValue.len)
            
            for i in 0..<fnDecl.params.len:
              let expectedType = fnDecl.params[i].typ
              let argValue = arguments.argsValue[i]
              let actualType = getValueType(argValue)
              
              # check type mismatch
              # todo: potentially add support for implicit type conversion
              # dunno how to represent that well without making it look bad
              if expectedType != actualType and expectedType != "any" and 
                 not (expectedType == "float" and actualType == "int"):
                raise newException(ValueError, "Type mismatch in call to '" & funcName & 
                  "'. Parameter '" & fnDecl.params[i].name & "' expects '" & 
                  expectedType & "', got '" & actualType & "'")
  
  # run the function if it's all good
  return callee.funcValue(arguments)

proc evaluate(interpreter: Interpreter, node: Node): Value =
  print "evaluating ", node.kind
  try:
    case node.kind
    of nkProgram:
      var lastValue = Value(kind: vtNil)
      for statement in node.statements:
        lastValue = interpreter.evaluate(statement)
      return lastValue
    of nkLiteral:
      case node.literalType
      of "int": return Value(kind: vtInt, intValue: parseInt(node.literalValue))
      of "float": return Value(kind: vtFloat, floatValue: parseFloat(node.literalValue))
      of "string": return Value(kind: vtString, stringValue: node.literalValue)
      of "bool": return Value(kind: vtBool, boolValue: parseBool(node.literalValue))
      of "operator": return Value(kind: vtOperator, binaryExpr: node)
      of "error": 
        echo node.literalValue
        quit(1)
      else: raise newException(ValueError, "Unknown literal type")
    of nkIdentifier:
      return interpreter.environment.get(node.identifierName)
    of nkBinaryExpr:
      return interpreter.evaluateBinaryExpr(node)
    of nkUnaryExpr:
      return interpreter.evaluateUnaryExpr(node)
    of nkVarDecl:
      return interpreter.evaluateVarDecl(node)
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
  except:
    echo "Error: ", getCurrentExceptionMsg()
    quit(1)
    #return Value(kind: vtNil)
    
  #else:
  #  raise newException(ValueError, "Unexpected node type: " & $node.kind)

include "inc/builtins.nim" # builtin funcs (impure)

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
  try:
    # Attempts to find a main function if it exists, otherwise we bail for now
    discard interpreter.evaluate(node)
    let mainFunc = interpreter.findMainFunction()
    if mainFunc.isSome:
      print("Calling main function")
      discard interpreter.evaluateCall(Node(kind: nkCall, callee: Node(
          kind: nkIdentifier, identifierName: "main"), arguments: @[]))
    else:
      echo "No main function found, create a function named 'main' to run your program."
      quit(0)
  except:
    let e = getCurrentException()
    let msg = getCurrentExceptionMsg()
    echo "Error: ", msg
    quit(1)