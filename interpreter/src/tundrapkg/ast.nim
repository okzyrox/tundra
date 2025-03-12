## AST

type
  NodeKind* = enum
    nkProgram, nkVarDecl, nkConstDecl, nkFunctionDecl, nkIfStmt, nkWhileStmt,
    nkForStmt, nkBreakStmt, nkReturnStmt, nkExprStmt, nkBinaryExpr, nkUnaryExpr,
    nkLiteral, nkIdentifier, nkCall

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
      params*: seq[tuple[name: string, typ: string]]
      returnType*: string
      body*: seq[Node]
    of nkIfStmt:
      condition*: Node
      thenBranch*: seq[Node]
      elseBranch*: seq[Node]
    of nkWhileStmt, nkForStmt:
      loopCondition*: Node
      loopBody*: seq[Node]
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