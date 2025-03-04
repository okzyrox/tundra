## Parser

import lex
import ast

import utils

type Parser = object
  tokens: seq[Token]
  current: int

proc newParser*(tokens: seq[Token]): Parser =
  Parser(tokens: tokens, current: 0)

proc peek(parser: Parser): Token =
  parser.tokens[parser.current]

proc advance(parser: var Parser): Token =
  result = parser.tokens[parser.current]
  inc parser.current

proc match(parser: var Parser, kinds: varargs[TokenKind]): bool =
  if parser.peek().kind in kinds:
    discard parser.advance()
    return true
  return false

proc atEnd(parser: Parser): bool =
  parser.peek().kind == tkEOF

proc check(parser: Parser, kind: TokenKind): bool =
  if parser.atEnd(): return false
  parser.peek().kind == kind

proc consume(parser: var Parser, kind: TokenKind, message: string): Token =
  if parser.check(kind): return parser.advance()
  let token = parser.peek()
  let errorMsg = "Line " & $token.line & ", Col " & $token.column & ": " & message & 
                " Got '" & token.lexeme & "' instead."
  raise newException(ValueError, errorMsg)

proc parseExpression(parser: var Parser): Node
proc parseStatement(parser: var Parser): Node

proc parseCall(parser: var Parser, callee: Node): Node =
  var arguments: seq[Node] = @[]
  if not parser.check(tkBracketClose):
    arguments.add(parser.parseExpression())
    while parser.match(tkSymbol) and parser.tokens[parser.current - 1].lexeme == ",":
      arguments.add(parser.parseExpression())
  
  discard parser.consume(tkBracketClose, "Expected ')' after arguments.")
  return Node(kind: nkCall, callee: callee, arguments: arguments)

proc parsePrimary(parser: var Parser): Node =
  try:
    if parser.match(tkInt):
      return Node(kind: nkLiteral, literalValue: parser.tokens[parser.current - 1].lexeme, literalType: "int")
    elif parser.match(tkFloat):
      return Node(kind: nkLiteral, literalValue: parser.tokens[parser.current - 1].lexeme, literalType: "float")
    elif parser.match(tkString):
      return Node(kind: nkLiteral, literalValue: parser.tokens[parser.current - 1].lexeme, literalType: "string")
    elif parser.match(tkIdent):
      let identifier = Node(kind: nkIdentifier, identifierName: parser.tokens[parser.current - 1].lexeme)
      if parser.match(tkBracketOpen):
        return parser.parseCall(identifier)
      return identifier
    elif parser.match(tkBracketOpen):
      let expr = parser.parseExpression()
      discard parser.consume(tkBracketClose, "Expected ')' after expression.")
      return expr
    elif parser.match(tkOperator):
      return Node(kind: nkLiteral, literalValue: parser.tokens[parser.current - 1].lexeme, literalType: "operator")
    else:
      return Node(kind: nkLiteral, literalValue: "ERROR", literalType: "error")
  except:
    return Node(kind: nkLiteral, literalValue: "ERROR -" & getCurrentExceptionMsg(), literalType: "error")

proc parseUnary(parser: var Parser): Node =
  if parser.match(tkOperator) and parser.tokens[parser.current - 1].lexeme in ["+", "-"]:
    let operator = parser.tokens[parser.current - 1].lexeme
    let right = parser.parseUnary()
    return Node(kind: nkUnaryExpr, operand: right, unaryOperator: operator)
  return parser.parsePrimary()

proc parseMultiplicative(parser: var Parser): Node =
  var left = parser.parseUnary()
  
  while parser.check(tkOperator) and parser.peek().lexeme in ["*", "/"]:
    let operator = parser.advance().lexeme
    let right = parser.parseUnary()
    left = Node(kind: nkBinaryExpr, left: left, right: right, operator: operator)
  
  return left

proc parseAdditive(parser: var Parser): Node =
  var left = parser.parseMultiplicative()
  
  while parser.check(tkOperator) and parser.peek().lexeme in ["+", "-"]:
    let operator = parser.advance().lexeme
    let right = parser.parseMultiplicative()
    left = Node(kind: nkBinaryExpr, left: left, right: right, operator: operator)
  
  return left

proc parseExpression(parser: var Parser): Node =
  return parser.parseAdditive()

proc parseVarDecl(parser: var Parser): Node =
  discard parser.advance() # consume 'var'
  let name = parser.consume(tkIdent, "Expected variable name.").lexeme
  var typ = ""
  if parser.match(tkSymbol) and parser.tokens[parser.current - 1].lexeme == ":":
    typ = parser.consume(tkIdent, "Expected type after ':'.").lexeme
  discard parser.consume(tkEquals, "Expected '=' after variable name.")
  let value = parser.parseExpression()
  Node(kind: nkVarDecl, name: name, typ: typ, value: value)

proc parseFunctionDecl(parser: var Parser): Node =
  discard parser.advance() # consume 'fn'
  let name = parser.consume(tkIdent, "Expected function name.").lexeme
  print "Function name: ", name
  discard parser.consume(tkBracketOpen, "Expected '(' after function name.")
  var params: seq[tuple[name: string, typ: string]] = @[]

  if not parser.check(tkBracketClose):
    while true:
      if parser.atEnd() or parser.check(tkBracketClose): break
      let paramName = parser.consume(tkIdent, "Expected parameter name.").lexeme
      discard parser.consume(tkSymbol, "Expected ':' after parameter name.")
      let paramType = parser.consume(tkIdent, "Expected parameter type.").lexeme
      params.add((name: paramName, typ: paramType))
      if not parser.check(tkSymbol) or parser.peek().lexeme != ",": break
      discard parser.advance() # consume ','

  discard parser.consume(tkBracketClose, "Expected ')' after parameters.")
  discard parser.consume(tkBraceOpen, "Expected '{' before function body.")
  var body: seq[Node] = @[]
  while not parser.check(tkBraceClose):
    if parser.atEnd(): break
    body.add(parser.parseStatement())
  discard parser.consume(tkBraceClose, "Expected '}' after function body.")
  Node(kind: nkFunctionDecl, fnName: name, params: params, body: body)

proc parseExpressionStatement(parser: var Parser): Node =
  let expr = parser.parseExpression()
  if parser.peek().kind == tkSymbol and parser.peek().lexeme == ";":
    discard parser.advance()
  Node(kind: nkExprStmt, expr: expr)

proc parseReturnStmt(parser: var Parser): Node =
  discard parser.advance() # consume 'return'
  let value = parser.parseExpression()
  Node(kind: nkReturnStmt, returnValue: value)

proc parseStatement(parser: var Parser): Node =
  print "Parsing statement, current token: ", parser.peek().kind
  try:
    if parser.peek().kind == tkKeyword:
      case parser.peek().lexeme
      of "var":
        return parser.parseVarDecl()
      of "fn":
        return parser.parseFunctionDecl()
      of "return":
        return parser.parseReturnStmt()
      else:
        echo "Unexpected keyword: ", parser.peek().lexeme
        return Node(kind: nkExprStmt, expr: parser.parseExpression())
    elif parser.peek().kind == tkIdent:
      return parser.parseExpressionStatement()
    elif parser.peek().kind == tkOperator:
      return parser.parseExpressionStatement()
    elif parser.peek().kind == tkInt:
      return parser.parseExpressionStatement()
    elif parser.peek().kind == tkFloat:
      return parser.parseExpressionStatement()
    elif parser.peek().kind == tkString:
      return parser.parseExpressionStatement()
    else:
      echo "Unexpected token in statement: ", parser.peek().kind
      discard parser.advance()
      return Node(kind: nkExprStmt, expr: Node(kind: nkLiteral, literalValue: "ERROR", literalType: "error"))
  except:
    return Node(kind: nkExprStmt, expr: Node(kind: nkLiteral, literalValue: "ERROR - " & getCurrentExceptionMsg(), literalType: "error"))

proc parse*(parser: var Parser): Node =
  var statements: seq[Node] = @[]
  print "Starting parsing, total tokens: ", parser.tokens.len
  while not parser.atEnd() and parser.peek().kind != tkEOF:
    print("Parsing statement at position: ", parser.current)
    let statement = parser.parseStatement()
    print "Statement parsed: ", statement.kind
    statements.add(statement)
  print "Parsing complete, total statements: ", statements.len
  Node(kind: nkProgram, statements: statements)
