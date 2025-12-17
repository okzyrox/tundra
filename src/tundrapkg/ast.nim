## AST

import std/[json]

type
  NodeKind* = enum
    nkProgram, nkVarDecl, nkConstDecl, nkFunctionDecl, nkIfStmt, nkWhileStmt,
    nkForStmt, nkBreakStmt, nkReturnStmt, nkExprStmt, nkBinaryExpr, nkUnaryExpr,
    nkLiteral, nkIdentifier, nkCall, nkArray, nkTable, nkIndexAccess, nkRange

  Node* = ref object
    case kind*: NodeKind
    of nkProgram:
      statements*: seq[Node]
    of nkVarDecl, nkConstDecl:
      name*: string
      typ*: string
      value*: Node
    of nkFunctionDecl:
      fnName*: string
      params*: seq[tuple[name: string, typ: string, optional: bool]]
      returnType*: string
      body*: seq[Node]
    of nkIfStmt:
      condition*: Node
      thenBranch*: seq[Node]
      elseBranch*: seq[Node]
    of nkWhileStmt:
      loopCondition*: Node
      loopBody*: seq[Node]
    of nkForStmt:
      forLoopVars*: seq[string]
      forLoopIterable*: Node
      forLoopBody*: seq[Node] # we cant name this the same as loopBody because Nim....
    of nkBreakStmt:
      discard
    of nkReturnStmt:
      returnValue*: Node
    of nkExprStmt:
      expr*: Node
    of nkBinaryExpr:
      left*, right*: Node
      operator*: string
    of nkUnaryExpr:
      operand*: Node
      unaryOperator*: string
    of nkLiteral:
      literalValue*: string
      literalType*: string
    of nkIdentifier:
      identifierName*: string
    of nkCall:
      callee*: Node
      arguments*: seq[Node]
    of nkTable:
      fields*: seq[tuple[key: Node, value: Node]]
    of nkArray:
      elements*: seq[Node]
      count*: int # cache
    of nkIndexAccess:
      target*: Node
      index*: Node
    of nkRange:
      rangeStart*: Node
      rangeEnd*: Node

proc `$`*(nodeKind: NodeKind): string =
  result = case nodeKind
  of nkProgram: "Program"
  of nkVarDecl: "VarDecl"
  of nkConstDecl: "ConstDecl"
  of nkFunctionDecl: "FunctionDecl"
  of nkIfStmt: "IfStmt"
  of nkWhileStmt: "WhileStmt"
  of nkForStmt: "ForStmt"
  of nkBreakStmt: "BreakStmt"
  of nkReturnStmt: "ReturnStmt"
  of nkExprStmt: "ExprStmt"
  of nkBinaryExpr: "BinaryExpr"
  of nkUnaryExpr: "UnaryExpr"
  of nkLiteral: "Literal"
  of nkIdentifier: "Identifier"
  of nkCall: "Call"
  of nkArray: "Array"
  of nkTable: "Table"
  of nkIndexAccess: "IndexAccess"
  of nkRange: "Range"
  # else: "Unknown"

proc `$`*(node: Node): string =
  result = "Node(" & $node.kind & ")"

proc `%`*(node: Node): JsonNode =
  result = newJObject()
  result["kind"] = %($node.kind)
  case node.kind
  of nkProgram:
    result["statements"] = newJArray()
    for stmt in node.statements:
      result["statements"].add(%stmt)
  of nkVarDecl, nkConstDecl:
    result["name"] = %node.name
    result["typ"] = %node.typ
    result["value"] = %node.value
  of nkFunctionDecl:
    result["fnName"] = %node.fnName
    result["params"] = newJArray()
    for param in node.params:
      var paramJson = newJObject()
      paramJson["name"] = %param.name
      paramJson["typ"] = %param.typ
      paramJson["optional"] = %param.optional
      result["params"].add(paramJson)
    result["returnType"] = %node.returnType
    result["body"] = newJArray()
    for stmt in node.body:
      result["body"].add(%stmt)
  of nkIfStmt:
    result["condition"] = %node.condition
    result["thenBranch"] = newJArray()
    for stmt in node.thenBranch:
      result["thenBranch"].add(%stmt)
    result["elseBranch"] = newJArray()
    for stmt in node.elseBranch:
      result["elseBranch"].add(%stmt)
  of nkWhileStmt:
    result["loopCondition"] = %node.loopCondition
    result["loopBody"] = newJArray()
    for stmt in node.loopBody:
      result["loopBody"].add(%stmt)
  of nkForStmt:
    result["forLoopVars"] = newJArray()
    for varName in node.forLoopVars:
      result["forLoopVars"].add(%varName)
    result["forLoopIterable"] = %node.forLoopIterable
    result["forLoopBody"] = newJArray()
    for stmt in node.forLoopBody:
      result["forLoopBody"].add(%stmt)
  of nkBreakStmt:
    discard
  of nkReturnStmt:
    result["returnValue"] = %node.returnValue
  of nkExprStmt:
    result["expr"] = %node.expr
  of nkBinaryExpr:
    result["left"] = %node.left
    result["right"] = %node.right
    result["operator"] = %node.operator
  of nkUnaryExpr:
    result["operand"] = %node.operand
    result["unaryOperator"] = %node.unaryOperator
  of nkLiteral:
    result["literalValue"] = %node.literalValue
    result["literalType"] = %node.literalType
  of nkIdentifier:
    result["identifierName"] = %node.identifierName
  of nkCall:
    result["callee"] = %node.callee
    result["arguments"] = newJArray()
    for arg in node.arguments:
      result["arguments"].add(%arg)
  of nkTable:
    result["fields"] = newJArray()
    for field in node.fields:
      var fieldJson = newJObject()
      fieldJson["key"] = %field.key
      fieldJson["value"] = %field.value
      result["fields"].add(fieldJson)
  of nkArray:
    result["elements"] = newJArray()
    for elem in node.elements:
      result["elements"].add(%elem)
    result["count"] = %node.count
  of nkIndexAccess:
    result["target"] = %node.target
    result["index"] = %node.index
  of nkRange:
    result["rangeStart"] = %node.rangeStart
    result["rangeEnd"] = %node.rangeEnd
  # else:
  #   discard

proc dumpJson*(node: Node): JsonNode =
  if node.kind == nkProgram:
    result = newJObject()
    result = %node
  else:
    raise newException(ValueError, "Invalid node for dump")