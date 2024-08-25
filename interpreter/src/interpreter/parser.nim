## Parser

import lex
import ast

import utils

type Parser = object
  tokens: seq[Token]
  current: int

proc newParser*(tokens: seq[Token]): Parser =
  Parser(tokens: tokens, current: 0)

proc peek(self: Parser): Token =
  self.tokens[self.current]

proc advance(self: var Parser): Token =
  result = self.tokens[self.current]
  inc self.current

proc match(self: var Parser, kinds: varargs[TokenKind]): bool =
  if self.peek().kind in kinds:
    discard self.advance()
    return true
  return false

proc parseExpression(self: var Parser): Node
proc parseStatement(self: var Parser): Node

proc parsePrimary(self: var Parser): Node =
  if self.match(tkInt):
    return Node(kind: nkLiteral, literalValue: self.tokens[self.current -
        1].lexeme, literalType: "int")
  elif self.match(tkFloat):
    return Node(kind: nkLiteral, literalValue: self.tokens[self.current -
        1].lexeme, literalType: "float")
  elif self.match(tkString):
    return Node(kind: nkLiteral, literalValue: self.tokens[self.current -
        1].lexeme, literalType: "string")
  elif self.match(tkIdent):
    return Node(kind: nkIdentifier, identifierName: self.tokens[self.current - 1].lexeme)
  else:
    return Node(kind: nkLiteral, literalValue: "ERROR", literalType: "error")

proc parseUnary(self: var Parser): Node =
  if self.match(tkSymbol): # Assuming '-' and '!' are tokenized as symbols
    let operator = self.tokens[self.current - 1].lexeme
    let right = self.parseUnary()
    return Node(kind: nkUnaryExpr, operand: right, unaryOperator: operator)
  return self.parsePrimary()

proc parseFactor(self: var Parser): Node =
  var expr = self.parseUnary()
  while self.match(tkSymbol): # Assuming '*' and '/' are tokenized as symbols
    let operator = self.tokens[self.current - 1].lexeme
    let right = self.parseUnary()
    expr = Node(kind: nkBinaryExpr, left: expr, right: right,
        operator: operator)
  return expr

proc parseTerm(self: var Parser): Node =
  var expr = self.parseFactor()
  while self.match(tkSymbol): # Assuming '+' and '-' are tokenized as symbols
    let operator = self.tokens[self.current - 1].lexeme
    let right = self.parseFactor()
    expr = Node(kind: nkBinaryExpr, left: expr, right: right,
        operator: operator)
  return expr

proc parseExpression(self: var Parser): Node =
  self.parseTerm()

proc parseVarDecl(self: var Parser): Node =
  discard self.advance() # cons var
  let name = self.advance().lexeme
  var typ = ""
  if self.match(tkSymbol): # Assuming ':' is tokenized as a symbol
    typ = self.advance().lexeme
  discard self.advance() # cons =
  let value = self.parseExpression()
  Node(kind: nkVarDecl, name: name, typ: typ, value: value)

proc parseFunctionDecl(self: var Parser): Node =
  discard self.advance() # cons func
  let name = self.advance().lexeme
  discard self.advance() # cons ()
  var params: seq[tuple[name: string, typ: string]] = @[]

  while self.peek().kind != tkBracketClose:
    let paramName = self.advance().lexeme
    discard self.advance()
    let paramType = self.advance().lexeme
    params.add((name: paramName, typ: paramType))
    if self.peek().kind == tkSymbol and self.peek().lexeme == ",":
      discard self.advance()
  discard self.advance() # cons (close)
  discard self.advance() # cons {
  var body: seq[Node] = @[]
  while self.peek().kind != tkSymbol or self.peek().lexeme != "}":
    body.add(self.parseStatement())
  discard self.advance() # cons }
  Node(kind: nkFunctionDecl, fnName: name, params: params, body: body)

proc parseExpressionStatement(self: var Parser): Node =
  let expr = self.parseExpression()
  if self.peek().kind == tkSymbol and self.peek().lexeme == ";":
    discard self.advance()
  Node(kind: nkExprStmt, expr: expr)

proc parseStatement(self: var Parser): Node =
  print "Parsing statement, current token: ", self.peek().kind
  if self.peek().kind == tkKeyword:
    case self.peek().lexeme
    of "var":
      return self.parseVarDecl()
    of "fn":
      return self.parseFunctionDecl()
    else:
      echo "Unexpected keyword: ", self.peek().lexeme
      return Node(kind: nkExprStmt, expr: self.parseExpression())
  elif self.peek().kind == tkIdent:
    return self.parseExpressionStatement()
  else:
    echo "Unexpected token in statement: ", self.peek().kind
    discard self.advance()
    return Node(kind: nkExprStmt, expr: Node(kind: nkLiteral,
        literalValue: "ERROR", literalType: "error"))

proc parse*(self: var Parser): Node =
  var statements: seq[Node] = @[]
  echo "Starting parsing, total tokens: ", self.tokens.len
  while self.current < self.tokens.len and self.peek().kind != tkEOF:
    print("Parsing statement at position: ", self.current)
    let statement = self.parseStatement()
    print "Statement parsed: ", statement.kind
    statements.add(statement)
  print "Parsing complete, total statements: ", statements.len
  Node(kind: nkProgram, statements: statements)
