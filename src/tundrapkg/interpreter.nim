## The interpreter
##
import std/[tables, strutils, options, hashes]

import ast, utils

type
  ValueType = enum
    vtFunc, vtInt, vtFloat, vtString, vtBool, vtNil, vtArgs, vtOperator, vtIdentifier, vtTable, vtArray, vtRange

  Value = object
    case kind: ValueType
    of vtInt: intValue: int
    of vtFloat: floatValue: float
    of vtString: stringValue: string
    of vtBool: boolValue: bool
    of vtFunc: funcValue: proc(environment: Environment, args: Value): Value
    of vtOperator: binaryExpr: Node
    of vtArgs: argsValue: seq[Value]
    of vtIdentifier: identifierName: string
    of vtTable: tableValue: Table[Value, Value]
    of vtArray: 
      arrayValue: seq[Value]
      count: int
    of vtRange:
      rangeStart: int
      rangeEnd: int
    of vtNil: discard

  Environment = ref object
    values: Table[string, Value]
    parent: Environment

  Interpreter = ref object
    globals: Environment
    environment: Environment
    functionDeclarations*: Table[string, Node] # used for type checking and whatnot

type
  BreakException = object of CatchableError

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
  of vtNil:
    if b.kind != vtNil:
      return false
    return true
  of vtArray:
    if b.kind != vtArray:
      return false
    if a.count != b.count:
      return false
    for i in 0..<a.count:
      if a.arrayValue[i] != b.arrayValue[i]:
        return false
    return true
  of vtRange:
    if b.kind != vtRange:
      return false
    return a.rangeStart == b.rangeStart and a.rangeEnd == b.rangeEnd
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
  of vtArgs: return "args"
  of vtArray: return "array"
  of vtTable: return "table"
  of vtRange: return "range"
  of vtFunc: return "function"
  else: return "unknown"

proc hash(v: Value): Hash =
  case v.kind
  of vtInt: hash(v.intValue)
  of vtFloat: hash(v.floatValue)
  of vtString: hash(v.stringValue)
  of vtBool: hash(v.boolValue)
  else: hash(0)

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

proc set(env: Environment, ogValue: Value, newValue: Value) = # really sucks but the only way to update with func
  for key, val in env.values:
    if val == ogValue:
      env.values[key] = newValue
      return
  if env.parent != nil:
    env.parent.set(ogValue, newValue)
  else:
    raise newException(ValueError, "Undefined value to set.")

proc evaluate(interpreter: Interpreter, node: Node): Value

proc evaluateLiteral(interpreter: Interpreter, node: Node): Value =
  case node.literalType
    of "int": return Value(kind: vtInt, intValue: parseInt(node.literalValue))
    of "float": return Value(kind: vtFloat, floatValue: parseFloat(node.literalValue))
    of "string":
      var strValue = node.literalValue.strip(leading = true, trailing = true, chars = {'\"'}) # oops...
      return Value(kind: vtString, stringValue: strValue)
    of "bool": return Value(kind: vtBool, boolValue: parseBool(node.literalValue))
    of "operator": return Value(kind: vtOperator, binaryExpr: node)
    of "nil": return Value(kind: vtNil)
    of "error": 
      echo node.literalValue
      quit(1)
    else: raise newException(ValueError, "Unknown literal type")

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
  of vtTable:
    var output: seq[string] = @[]
    for key, val in v.tableValue:
      output.add($key & ": " & $val)
    "table{" & output.join(", ") & "}"
  of vtArray:
    var output: seq[string] = @[]
    for elem in v.arrayValue:
      output.add($elem)
    "array[" & output.join(", ") & "]"
  of vtRange:
    "range<" & $v.rangeStart & ".." & $v.rangeEnd & ">"
  else:
    "<unknown>"

proc delete(t: var Value, i: Value) =
  case t.kind
  of vtArray:
    if i.kind != vtInt:
      raise newException(ValueError, "Attempted to delete from array using non integer index " & $i)

    if i.intValue < 0 or i.intValue >= t.count:
      raise newException(ValueError, "Attempted to index array out of bounds")
  
    t.arrayValue.delete(i.intValue)
    t.count -= 1
  else:
    raise newException(ValueError, "Attempted to delete from non-array value using " & $i)

proc replace(t: var Value, i: Value, v: Value) =
  case t.kind
  of vtArray:
    if i.kind != vtInt:
      raise newException(ValueError, "Attempted to replace in array using non integer index " & $i)

    if i.intValue < 0 or i.intValue >= t.count:
      raise newException(ValueError, "Attempted to index array out of bounds")
  
    t.arrayValue[i.intValue] = v
  of vtTable:
    case t.kind
    of vtString, vtInt:
      t.tableValue[i] = v
    else:
      raise newException(ValueError, "Attempted to replace in table using non-string/int key " & $i)
  else:
    raise newException(ValueError, "Attempted to replace in non-array value using " & $i & " to " & $v)

proc insert(t: var Value, i: Value, v: Value) =
  case t.kind
  of vtArray:
    if i.kind != vtInt:
      raise newException(ValueError, "Attempted to insert into array using non integer index " & $i)

    if i.intValue < 0:
      raise newException(ValueError, "Attempted to index array out of bounds")
  
    if v.kind == vtNil:
      t.delete(i)
    else:
      t.arrayValue.insert(v, i.intValue)
      t.count += 1
  of vtTable:
    if i.kind == vtString or i.kind == vtInt:
      t.tableValue[i] = v
    else:
      raise newException(ValueError, "Attempted to insert into table using non-string/int key " & $i)
  else:
    raise newException(ValueError, "Attempted to insert into non-array value using " & $i & " to " & $v)

proc evaluateIdentifier(interpreter: Interpreter, node: Node): Value =
  interpreter.environment.get(node.identifierName)

proc evaluateBinaryExpr(interpreter: Interpreter, node: Node): Value =
  let left = interpreter.evaluate(node.left)
  let right = interpreter.evaluate(node.right)

  if (left.kind == vtNil or right.kind == vtNil) and (node.operator notin ["=", "==", "!=", ","]):
    raise newException(ValueError, "Attempted to use operation " & node.operator & " on " & getValueType(left) & " and " & getValueType(right))

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
          $right
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
  of "&&":
    if left.kind == vtBool and right.kind == vtBool:
      return Value(kind: vtBool, boolValue: left.boolValue and right.boolValue)
    if left.kind == vtInt and right.kind == vtInt:
      return Value(kind: vtBool, boolValue: (left.intValue != 0) and (right.intValue != 0))
    else:
      discard
  of "||":
    if left.kind == vtBool and right.kind == vtBool:
      return Value(kind: vtBool, boolValue: left.boolValue or right.boolValue)
    if left.kind == vtInt and right.kind == vtInt:
      return Value(kind: vtBool, boolValue: (left.intValue != 0) or (right.intValue != 0))
    else:
      discard
  of "==":
    return Value(kind: vtBool, boolValue: left == right)
  of "!=":
    return Value(kind: vtBool, boolValue: left != right)
  of ">":
    case left.kind
    of vtInt:
      if right.kind == vtInt:
        return Value(kind: vtBool, boolValue: left.intValue > right.intValue)
    of vtFloat:
      if right.kind == vtFloat:
        return Value(kind: vtBool, boolValue: left.floatValue > right.floatValue)
    else:
      discard
  of "<":
    case left.kind
    of vtInt:
      if right.kind == vtInt:
        return Value(kind: vtBool, boolValue: left.intValue < right.intValue)
    of vtFloat:
      if right.kind == vtFloat:
        return Value(kind: vtBool, boolValue: left.floatValue < right.floatValue)
    else:
      discard
  of ">=":
    case left.kind
    of vtInt:
      if right.kind == vtInt:
        return Value(kind: vtBool, boolValue: left.intValue >= right.intValue)
    of vtFloat:
      if right.kind == vtFloat:
        return Value(kind: vtBool, boolValue: left.floatValue >= right.floatValue)
    else:
      discard
  of "<=":
    case left.kind
    of vtInt:
      if right.kind == vtInt:
        return Value(kind: vtBool, boolValue: left.intValue <= right.intValue)
    of vtFloat:
      if right.kind == vtFloat:
        return Value(kind: vtBool, boolValue: left.floatValue <= right.floatValue)
    else:
      discard
  of ",":
    return Value(kind: vtArgs, argsValue: @[left, right])
  of "=":
    # if node.left.kind != nkIdentifier:
    #   raise newException(ValueError, "Cannot assign to non-identifier")
    if node.left.kind == nkIdentifier:
      let value = interpreter.evaluate(node.right)
      print("Assigning value " & $value & " to variable " & node.left.identifierName)
      try:
        interpreter.environment.set(node.left.identifierName, value)
      except ValueError:
        interpreter.environment.define(node.left.identifierName, value)
      return value
    elif node.left.kind == nkIndexAccess:
      if node.left.target.kind != nkIdentifier:
        raise newException(ValueError, "Cannot to index assign to something that is not an indentifier")
      
      let targetName = node.left.target.identifierName
      var target = interpreter.environment.get(targetName)

      let index = interpreter.evaluate(node.left.index)
      let value = interpreter.evaluate(node.right)

      target.replace(index, value)
      interpreter.environment.set(targetName, target)
      
      return value
    else:
      raise newException(ValueError, "Invalid assignment target")
  else:
    raise newException(ValueError, "Invalid operator for types " & 
      getValueType(left) & " and " & getValueType(right) & "are not compatible with " & node.operator)
  

proc evaluateVarDecl(interpreter: Interpreter, node: Node): Value =
  let value = interpreter.evaluate(node.value)
  interpreter.environment.define(node.name, value)
  print "Defined variable: ", node.name, " with value: ", value
  return value

proc evaluateFuncDecl(interpreter: Interpreter, node: Node) =
  if interpreter.functionDeclarations.hasKey(node.fnName):
    raise newException(ValueError, "A function with the name '" & node.fnName & "' is already defined.")

  let function = proc(environment: Environment, args: Value): Value =
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
    # new env; new scope
    let prevEnv = interpreter.environment
    interpreter.environment = newEnvironment(prevEnv)
    
    var res = Value(kind: vtNil)
    for stmt in node.thenBranch:
      res = interpreter.evaluate(stmt)
      if stmt.kind == nkReturnStmt:
        interpreter.environment = prevEnv
        return res
    
    # restore
    interpreter.environment = prevEnv
    return res
  elif node.elseBranch.len > 0:
    # other branches need new environments too
    let prevEnv = interpreter.environment
    interpreter.environment = newEnvironment(prevEnv)

    var res = Value(kind: vtNil)
    for stmt in node.elseBranch:
      res = interpreter.evaluate(stmt)
      if stmt.kind == nkReturnStmt:
        interpreter.environment = prevEnv
        return res
    
    # restore
    interpreter.environment = prevEnv
    return res
  else:
    return Value(kind: vtNil)

proc evaluateBreakStmt(interpreter: Interpreter, node: Node): Value =
  raise newException(BreakException, "break")

# Unfinished; slow
proc evaluateWhileStmt(interpreter: Interpreter, node: Node): Value =
  while true:
    let condition = interpreter.evaluate(node.loopCondition)
    if condition.kind != vtBool:
      raise newException(ValueError, "While condition must be a boolean")
      
    if not condition.boolValue:
      break

    # inner scope
    let prevEnv = interpreter.environment
    interpreter.environment = newEnvironment(prevEnv)
    
    # Exec body until break or false
    try:
      for stmt in node.loopBody:
        discard interpreter.evaluate(stmt)
    except BreakException:
      break
    finally:
      # restore env
      interpreter.environment = prevEnv
  
  return Value(kind: vtNil)

# nightmare fuel
proc evaluateForStmt(interpreter: Interpreter, node: Node): Value =
  let prevEnv = interpreter.environment
  interpreter.environment = newEnvironment(prevEnv)
  
  try:
    let kind = node.forLoopIterable.kind
    if kind == nkRange: # assume range (i.e. 1..10)
      let startVal = interpreter.evaluate(node.forLoopIterable.rangeStart)
      let endVal = interpreter.evaluate(node.forLoopIterable.rangeEnd)
      
      if startVal.kind != vtInt or endVal.kind != vtInt:
        raise newException(ValueError, "Range bounds must be integers")
      
      if node.forLoopVars.len != 1:
        raise newException(ValueError, "Range iteration requires exactly one loop variable")
      
      let rangeStart = startVal.intValue
      let rangeEnd = endVal.intValue
      let reverse = rangeStart > rangeEnd

      if reverse:
        for i in countdown(startVal.intValue, endVal.intValue):
          if i == startVal.intValue:
            interpreter.environment.define(node.forLoopVars[0], Value(kind: vtInt, intValue: i))
          else:
            interpreter.environment.set(node.forLoopVars[0], Value(kind: vtInt, intValue: i))
          for stmt in node.forLoopBody:
            discard interpreter.evaluate(stmt)
      else:
        for i in startVal.intValue..endVal.intValue: # wow the syntax is indentical where could i have gotten that from
          if i == startVal.intValue:
            interpreter.environment.define(node.forLoopVars[0], Value(kind: vtInt, intValue: i))
          else:
            interpreter.environment.set(node.forLoopVars[0], Value(kind: vtInt, intValue: i))
          for stmt in node.forLoopBody:
            discard interpreter.evaluate(stmt)

    else:
      let iterable = interpreter.evaluate(node.forLoopIterable)
      case iterable.kind
      of vtRange:
        if node.forLoopVars.len != 1:
          raise newException(ValueError, "Range iteration requires one assignable loop variable")
        
        let rangeStart = iterable.rangeStart
        let rangeEnd = iterable.rangeEnd
        let reverse = rangeStart > rangeEnd

        if reverse:
          for i in countdown(iterable.rangeStart, iterable.rangeEnd):
            if i == iterable.rangeStart:
              interpreter.environment.define(node.forLoopVars[0], Value(kind: vtInt, intValue: i))
            else:
              interpreter.environment.set(node.forLoopVars[0], Value(kind: vtInt, intValue: i))
            for stmt in node.forLoopBody:
              discard interpreter.evaluate(stmt)
        else:
          for i in iterable.rangeStart..iterable.rangeEnd:
            if i == iterable.rangeStart:
              interpreter.environment.define(node.forLoopVars[0], Value(kind: vtInt, intValue: i))
            else:
              interpreter.environment.set(node.forLoopVars[0], Value(kind: vtInt, intValue: i))
            for stmt in node.forLoopBody:
              discard interpreter.evaluate(stmt)
      of vtTable:
        var isFirst = true
        # only get key if 1 var
        if node.forLoopVars.len == 1:
          for key, value in iterable.tableValue:
            if isFirst:
              interpreter.environment.define(node.forLoopVars[0], key)
              isFirst = false
            else:
              interpreter.environment.set(node.forLoopVars[0], key)
            for stmt in node.forLoopBody:
              discard interpreter.evaluate(stmt)
        elif node.forLoopVars.len == 2:
          for key, value in iterable.tableValue:
            # set accessible kv values for da for loop
            if isFirst:
              interpreter.environment.define(node.forLoopVars[0], key)
              interpreter.environment.define(node.forLoopVars[1], value)
              isFirst = false
            else:
              interpreter.environment.set(node.forLoopVars[0], key)
              interpreter.environment.set(node.forLoopVars[1], value)
            for stmt in node.forLoopBody:
              discard interpreter.evaluate(stmt)
        else:
          raise newException(ValueError, "Invalid number of loop variables for table iteration")
      of vtArray:
        if node.forLoopVars.len != 1:
          raise newException(ValueError, "Invalid number of loop variables for array iteration")
        
        var isFirst = true
        for element in iterable.arrayValue:
          if isFirst:
            interpreter.environment.define(node.forLoopVars[0], element)
            isFirst = false
          else:
            interpreter.environment.set(node.forLoopVars[0], element)
          for stmt in node.forLoopBody:
            discard interpreter.evaluate(stmt)
      else:
        raise newException(ValueError, "Can only iterate over tables, arrays and ranges")
  except BreakException:
    discard
  finally:
    interpreter.environment = prevEnv # restore env; TODO: make auto?
  
  return Value(kind: vtNil)

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
              let isOptional = fnDecl.params[i].optional
              # check type mismatch
              # todo: potentially add support for implicit type conversion
              # dunno how to represent that well without making it look bad

              if isOptional and actualType == "nil":
                continue
              
              if expectedType != actualType and expectedType != "any" and 
                 not (expectedType == "float" and actualType == "int"):
                raise newException(ValueError, "Type mismatch in call to '" & funcName & 
                  "'. Parameter '" & fnDecl.params[i].name & "' expects '" & 
                  expectedType & "', got '" & actualType & "'")
  
  # run the function if it's all good
  return callee.funcValue(interpreter.environment, arguments)

proc evaluateTable(interpreter: Interpreter, node: Node): Value =
  var table = initTable[Value, Value]()
  for field in node.fields:
    let key = interpreter.evaluate(field.key)
    let value = interpreter.evaluate(field.value)
    table[key] = value
  return Value(kind: vtTable, tableValue: table)

proc evaluateArray(interpreter: Interpreter, node: Node): Value =
  var elements = newSeq[Value](0)
  for elementNode in node.elements:
    let elementValue = interpreter.evaluate(elementNode)
    elements.add(elementValue)
  return Value(kind: vtArray, arrayValue: elements, count: elements.len)

proc evaluateIndexAccess(interpreter: Interpreter, node: Node): Value =
  let target = interpreter.evaluate(node.target)
  let index = interpreter.evaluate(node.index)
  
  # limited to tables, may change in the future; both for arrays 
  # and strings if i want to do something like
  # ```
  # var s = "hello"
  # print(s[0]) # h
  # ```
  # or something...
  if target.kind == vtTable:
    if target.tableValue.hasKey(index):
      return target.tableValue[index]
    else:
      return Value(kind: vtNil)  # Return nil for non-existent keys
  elif target.kind == vtArray:
    if index.kind == vtInt:
      if index.intValue < 0 or index.intValue >= target.count:
        raise newException(ValueError, "Array index out of bounds")
      return target.arrayValue[index.intValue]
    elif index.kind == vtRange: # slice
      let startIndex = index.rangeStart
      let endIndex = index.rangeEnd
      if startIndex < 0 or endIndex >= target.count or startIndex > endIndex:
        raise newException(ValueError, "Array slice index out of bounds")
      let slice = target.arrayValue[startIndex..endIndex]
      return Value(kind: vtArray, arrayValue: slice, count: slice.len)
    else:
      raise newException(ValueError, "Array index must be an integer or range")
  elif target.kind == vtString:
    if index.kind != vtInt:
      raise newException(ValueError, "String index must be an integer")
    if index.intValue < 0 or index.intValue >= target.stringValue.len:
      raise newException(ValueError, "String index out of bounds")
    let charValue = target.stringValue[index.intValue]
    return Value(kind: vtString, stringValue: $charValue)
  elif target.kind == vtNil:
    raise newException(ValueError, "Cannot index into a nil value")
  else:
    raise newException(ValueError, "Cannot index into type " & getValueType(target))
  
  

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
      return interpreter.evaluateLiteral(node)
    of nkIdentifier:
      return interpreter.evaluateIdentifier(node)
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
    of nkBreakStmt:
      return interpreter.evaluateBreakStmt(node)
    of nkReturnStmt:
      return interpreter.evaluateReturnStmt(node)
    of nkExprStmt:
      return interpreter.evaluate(node.expr)
    of nkCall:
      return interpreter.evaluateCall(node)
    of nkTable:
      return interpreter.evaluateTable(node)
    of nkArray:
      return interpreter.evaluateArray(node)
    of nkIndexAccess:
      return interpreter.evaluateIndexAccess(node)
    of nkRange:
      let startVal = interpreter.evaluate(node.rangeStart)
      let endVal = interpreter.evaluate(node.rangeEnd)
      if startVal.kind != vtInt or endVal.kind != vtInt:
        raise newException(ValueError, "Range bounds must be integers")
      return Value(kind: vtRange, rangeStart: startVal.intValue, rangeEnd: endVal.intValue)
    # else:
    #   raise newException(ValueError, "Unexpected node type: " & $node.kind)
  except BreakException:
    print("Broken out of loop")
    raise newException(BreakException, getCurrentExceptionMsg())
  except:
    echo "Evaluation Error: ", getCurrentExceptionMsg()
    quit(-1)
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
      quit(-1)
  except:
    # let e = getCurrentException()
    let msg = getCurrentExceptionMsg()
    echo "Error: ", msg
    quit(-1)
