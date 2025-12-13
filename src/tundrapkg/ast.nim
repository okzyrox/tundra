## AST

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
  else: "Unknown"

proc `$`*(node: Node): string =
  result = "Node(" & $node.kind & ")"