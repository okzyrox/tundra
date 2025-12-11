## Parser

import lex
import ast

import utils

type Parser = object
  tokens: seq[Token]
  current: int

type ParserError = object of ValueError

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

proc throwParserError(parser: var Parser, message: string, got: bool = false) =
  let token = parser.peek()
  var errorMsg = "Line " & $token.line & ", Col " & $token.column & ": " & message
  if got:
    errorMsg = errorMsg & " Got '" & token.lexeme & "' instead."
  raise newException(ParserError, errorMsg)

proc consume(parser: var Parser, kind: TokenKind, message: string): Token =
  if parser.check(kind): return parser.advance()
  # otherwise..:
  throwParserError(parser, message, true)

proc parseExpression(parser: var Parser): Node
proc parseStmt(parser: var Parser): Node

proc parseCall(parser: var Parser, callee: Node): Node =
  var arguments: seq[Node] = @[]
  if not parser.check(tkBracketClose):
    arguments.add(parser.parseExpression())
    while parser.match(tkSymbol) and parser.tokens[parser.current - 1].lexeme == ",":
      arguments.add(parser.parseExpression())
  
  discard parser.consume(tkBracketClose, "Expected ')' after arguments.")
  return Node(kind: nkCall, callee: callee, arguments: arguments)

proc parseTable(parser: var Parser): Node =
  print "Parsing table literal"
  var fields: seq[tuple[key: Node, value: Node]] = @[]

  # we parse until we have an end; 
  # although this is unsafe asf (but i kinda havent found too many issues yet soooo...)
  if not parser.check(tkBraceClose): 
    while true: # todo: make this less infinite
      let key = parser.parseExpression() # todo: ensure only integer/string keys (although bool tables are funny)
      
      discard parser.consume(tkSymbol, "Expected ':' after table key.")
      if parser.tokens[parser.current - 1].lexeme != ":":
        throwParserError(parser, "Expected ':' after table key.")
      
      let value = parser.parseExpression()
      fields.add((key: key, value: value))
      
      # a comma means we can move on, probably...
      if not parser.match(tkSymbol) or parser.tokens[parser.current - 1].lexeme != ",":
        break
  
  discard parser.consume(tkBraceClose, "Expected '}' after table literal.")
  return Node(kind: nkTable, fields: fields)

proc parseIndexAccess(parser: var Parser, target: Node): Node =
  # todo: need support for chaining index accesses (i.e. x[0][1][2])
  print "Parsing index access"
  let index = parser.parseExpression()
  discard parser.consume(tkSquareBracketClose, "Expected ']' after index.")
  return Node(kind: nkIndexAccess, target: target, index: index)  

proc parsePrimary(parser: var Parser): Node =
  try:
    if parser.match(tkInt):
      return Node(kind: nkLiteral, literalValue: parser.tokens[parser.current - 1].lexeme, literalType: "int")
    elif parser.match(tkFloat):
      return Node(kind: nkLiteral, literalValue: parser.tokens[parser.current - 1].lexeme, literalType: "float")
    elif parser.match(tkString):
      return Node(kind: nkLiteral, literalValue: parser.tokens[parser.current - 1].lexeme, literalType: "string")
    elif parser.match(tkBool):
      return Node(kind: nkLiteral, literalValue: parser.tokens[parser.current - 1].lexeme, literalType: "bool")
    elif parser.match(tkNil):
      return Node(kind: nkLiteral, literalValue: parser.tokens[parser.current - 1].lexeme, literalType: "nil")
    elif parser.match(tkIdent):
      let identifier = Node(kind: nkIdentifier, identifierName: parser.tokens[parser.current - 1].lexeme)
      if parser.match(tkBracketOpen):
        return parser.parseCall(identifier)
      elif parser.match(tkSquareBracketOpen):
        return parser.parseIndexAccess(identifier)
      return identifier
    elif parser.match(tkBracketOpen):
      let expr = parser.parseExpression()
      discard parser.consume(tkBracketClose, "Expected ')' after expression.")
      return expr
    elif parser.match(tkBraceOpen):
      return parser.parseTable()
    elif parser.match(tkOperator):
      return Node(kind: nkLiteral, literalValue: parser.tokens[parser.current - 1].lexeme, literalType: "operator")
    else:
      return Node(kind: nkLiteral, literalValue: "ERROR", literalType: "error")
  except:
    return Node(kind: nkLiteral, literalValue: "ERROR -" & getCurrentExceptionMsg(), literalType: "error")

proc parseUnary(parser: var Parser): Node =
  if parser.match(tkOperator) and parser.tokens[parser.current - 1].lexeme in ["+", "-", "!"]:
    let operator = parser.tokens[parser.current - 1].lexeme
    let right = parser.parseUnary()
    return Node(kind: nkUnaryExpr, operand: right, unaryOperator: operator)
  return parser.parsePrimary()

proc parseMultiplicative(parser: var Parser): Node =
  var left = parser.parseUnary()
  
  while parser.check(tkOperator) and parser.peek().lexeme in ["*", "/", "%", "^"]:
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
  
  while parser.check(tkOperator) and parser.peek().lexeme == "..":
    discard parser.advance() # consume ..
    let right = parser.parseMultiplicative()
    left = Node(kind: nkRange, rangeStart: left, rangeEnd: right)

  return left

proc parseComparison(parser: var Parser): Node =
  var left = parser.parseAdditive()
  while parser.check(tkOperator) and parser.peek().lexeme in ["==", "!=", "<", "<=", ">", ">="]:
    let operator = parser.advance().lexeme
    let right = parser.parseAdditive()
    left = Node(kind: nkBinaryExpr, left: left, right: right, operator: operator)
  
  return left

proc parseAssignment(parser: var Parser): Node =
  var left = parser.parseComparison()
  
  if parser.check(tkEquals) and parser.peek().lexeme == "=":
    discard parser.advance() # consume equals sign
    let value = parser.parseExpression()
    
    if left.kind == nkIdentifier:
      return Node(kind: nkBinaryExpr, left: left, right: value, operator: "=")
    elif left.kind == nkIndexAccess:
      # x["key"] = value
      return Node(kind: nkBinaryExpr, left: left, right: value, operator: "=")
    else:
      throwParserError(parser, "Invalid assignment target")
  
  return left

proc parseExpression(parser: var Parser): Node =
  return parser.parseAssignment()
  #return parser.parseComparison()

proc parseVarDecl(parser: var Parser): Node =
  discard parser.advance() # consume 'var'
  let name = parser.consume(tkIdent, "Expected variable name.").lexeme
  var typ = ""
  if parser.match(tkSymbol) and parser.tokens[parser.current - 1].lexeme == ":":
    typ = parser.consume(tkIdent, "Expected type after ':'.").lexeme
  
  var value: Node
  try:
    discard parser.consume(tkEquals, "Expected '=' after variable name.")
    value = parser.parseExpression()
  except ParserError:
    value = Node(kind: nkLiteral, literalValue: "nil", literalType: "nil")
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
      if not (paramType in ["int", "float", "string", "bool"]):
        throwParserError(parser, "Invalid parameter type: '" & paramType & "'.", false)
      params.add((name: paramName, typ: paramType))
      if not parser.check(tkSymbol) or parser.peek().lexeme != ",": break
      discard parser.advance() # consume ','

  discard parser.consume(tkBracketClose, "Expected ')' after parameters.")
  discard parser.consume(tkBraceOpen, "Expected '{' before function body.")
  var body: seq[Node] = @[]
  while not parser.check(tkBraceClose):
    if parser.atEnd(): break
    body.add(parser.parseStmt())
  discard parser.consume(tkBraceClose, "Expected '}' after function body.")
  Node(kind: nkFunctionDecl, fnName: name, params: params, body: body)

proc parseIfStmt(parser: var Parser): Node =
  discard parser.advance() # consume 'if'
  discard parser.consume(tkBracketOpen, "Expected '(' after 'if'.")
  let condition = parser.parseExpression()
  discard parser.consume(tkBracketClose, "Expected ')' after condition.")
  discard parser.consume(tkBraceOpen, "Expected '{' before if body.")
  
  var thenBranch: seq[Node] = @[]
  while not parser.check(tkBraceClose) and not parser.atEnd():
    thenBranch.add(parser.parseStmt())
  
  discard parser.consume(tkBraceClose, "Expected '}' after if body.")
  
  var elseBranch: seq[Node] = @[]
  if parser.check(tkKeyword) and parser.peek().lexeme == "else":
    discard parser.advance() # 'else'
    
    if parser.check(tkKeyword) and parser.peek().lexeme == "if":
      # else if case
      let elseIfNode = parser.parseIfStmt() # essentially like a nested if
      elseBranch.add(elseIfNode)
    else:
      discard parser.consume(tkBraceOpen, "Expected '{' before else body.")
      while not parser.check(tkBraceClose) and not parser.atEnd():
        elseBranch.add(parser.parseStmt())
      discard parser.consume(tkBraceClose, "Expected '}' after else body.")
  
  return Node(kind: nkIfStmt, condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)


proc parseBreakStmt(parser: var Parser): Node =
  discard parser.advance()
  Node(kind: nkBreakStmt)

proc parseForStmt(parser: var Parser): Node =
  discard parser.advance()
  discard parser.consume(tkBracketOpen, "Expected '(' after 'for'.")
  
  discard parser.consume(tkKeyword, "Expected 'var' in for loop.")
  if parser.tokens[parser.current - 1].lexeme != "var":
    throwParserError(parser, "Expected 'var' in for loop.")
  
  var loopVars: seq[string] = @[]
  loopVars.add(parser.consume(tkIdent, "Expected variable name.").lexeme)
  
  while parser.match(tkSymbol) and parser.tokens[parser.current - 1].lexeme == ",":
    loopVars.add(parser.consume(tkIdent, "Expected variable name after comma.").lexeme)
  
  discard parser.consume(tkKeyword, "Expected 'in' keyword.")
  if parser.tokens[parser.current - 1].lexeme != "in":
    throwParserError(parser, "Expected 'in' keyword in for loop.")

  # `do` is also disabled for the same aforementioned reasons in the parseWhileStmt block
  # because my keyword parser is BUGGY
  
  let iterable = parser.parseExpression()
  
  discard parser.consume(tkBracketClose, "Expected ')' after for loop header.")
  discard parser.consume(tkBraceOpen, "Expected '{' to start for loop body.")
  
  var body: seq[Node] = @[]
  while not parser.check(tkBraceClose) and not parser.atEnd():
    body.add(parser.parseStmt())
  
  discard parser.consume(tkBraceClose, "Expected '}' after for loop body.")
  
  return Node(kind: nkForStmt, forLoopVars: loopVars, forLoopIterable: iterable, forLoopBody: body)


proc parseWhileStmt(parser: var Parser): Node =
  print("Parsing while statement")
  discard parser.advance() # consume 'while'
  
  discard parser.consume(tkBracketOpen, "Expected '(' after 'while'.")
  let condition = parser.parseExpression()
  discard parser.consume(tkBracketClose, "Expected ')' after condition.")
  
  # disabled `do` cause of some issues
  # instead of `while (condition) do {}` just use `while (condition) {}`
  # the difference is minor
  
  # if parser.check(tkKeyword) and parser.peek().lexeme == "do":
  #   discard parser.advance() # consume 'do'
  
  discard parser.consume(tkBraceOpen, "Expected '{' before while loop body.")
  
  var body: seq[Node] = @[]
  while not parser.check(tkBraceClose) and not parser.atEnd():
    print("Parsing statement in while loop body. Current token: " & $parser.peek().kind)
    let statement = parser.parseStmt()
    body.add(statement)
  
  discard parser.consume(tkBraceClose, "Expected '}' after while loop body.")
  
  return Node(kind: nkWhileStmt, loopCondition: condition, loopBody: body)

proc parseExpressionStmt(parser: var Parser): Node =
  let expr = parser.parseExpression()
  if parser.peek().kind == tkSymbol and parser.peek().lexeme == ";":
    discard parser.advance()
  Node(kind: nkExprStmt, expr: expr)

proc parseReturnStmt(parser: var Parser): Node =
  discard parser.advance() # consume 'return'
  let value = parser.parseExpression()
  Node(kind: nkReturnStmt, returnValue: value)

proc parseStmt(parser: var Parser): Node =
  print "Parsing statement, current token: ", parser.peek().kind
  try:
    if parser.peek().kind == tkKeyword:
      var keyword = parser.peek().lexeme
      case keyword
      of "var":
        return parser.parseVarDecl()
      of "fn":
        return parser.parseFunctionDecl()
      of "if":
        return parser.parseIfStmt()
      of "while":
        return parser.parseWhileStmt()
      of "for":
        return parser.parseForStmt()
      of "break":
        return parser.parseBreakStmt()
      of "return":
        return parser.parseReturnStmt()
      else:
        echo "Unexpected keyword: ", parser.peek().lexeme
        return Node(kind: nkExprStmt, expr: parser.parseExpression())
    elif parser.peek().kind in [tkIdent, tkOperator, tkInt, tkFloat, tkString, tkBool, tkEquals]:
      return parser.parseExpressionStmt()
    else:
      echo "Unexpected token in statement: ", parser.peek().kind
      discard parser.advance()
      return Node(kind: nkExprStmt, expr: Node(kind: nkLiteral, literalValue: "PARSE ERROR", literalType: "error"))
  except:
    return Node(kind: nkExprStmt, expr: Node(kind: nkLiteral, literalValue: "ERROR - " & getCurrentExceptionMsg(), literalType: "error"))

proc parse*(parser: var Parser): Node =
  var statements: seq[Node] = @[]
  print "Starting parsing, total tokens: ", parser.tokens.len
  while not parser.atEnd() and parser.peek().kind != tkEOF:
    print("Parsing statement at position: ", parser.current)
    let statement = parser.parseStmt()
    print "Statement parsed: ", statement.kind
    statements.add(statement)
  print "Parsing complete, total statements: ", statements.len
  Node(kind: nkProgram, statements: statements)
