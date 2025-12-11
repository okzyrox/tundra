## LEXER
##


import std/strutils

import utils

type TokenKind* = enum
  tkKeyword
  tkIdent
  tkInt
  tkFloat
  tkString
  tkBool
  tkNil
  tkSymbol
  tkComment
  tkOperator
  tkBracketOpen
  tkBracketClose
  tkBraceOpen
  tkBraceClose
  tkSquareBracketOpen
  tkSquareBracketClose
  tkEquals
  tkEOF

proc `$`*(kind: TokenKind): string =
  case kind
  of tkKeyword: "Keyword"
  of tkIdent: "Identifier"
  of tkInt: "Integer"
  of tkFloat: "Float"
  of tkString: "String"
  of tkBool: "Boolean"
  of tkSymbol: "Symbol"
  of tkComment: "Comment"
  of tkOperator: "Operator"
  of tkBracketOpen: "Open Bracket (`(`)"
  of tkBracketClose: "Closed Bracket (`)`)"
  of tkBraceOpen: "Open Brace (`{`)"
  of tkBraceClose: "Closed Brace (`}`)"
  of tkSquareBracketOpen: "Open Square Bracket (`[`)"
  of tkSquareBracketClose: "Closed Square Bracket (`]`)"
  of tkEquals: "Equals (`=`)"
  of tkNil: "Nil"
  of tkEOF: "EOF"
  else: "Unknown"

type Token* = object
  kind*: TokenKind
  lexeme*: string
  line*: int
  column*: int


type Lexer* = object
  source*: string
  tokens*: seq[Token]
  start*: int
  current*: int
  line*: int
  col*: int

proc newLexer*(source: string): Lexer =
  Lexer(source: source, tokens: @[], start: 0, current: 0, line: 1, col: 1)

proc atEnd(lexer: Lexer): bool =
  lexer.current >= lexer.source.len

proc advance(lexer: var Lexer): char =
  print "advancing"
  result = lexer.source[lexer.current]
  inc lexer.current
  inc lexer.col

proc addToken(lexer: var Lexer, kind: TokenKind) =
  let lexeme = lexer.source[lexer.start..<lexer.current]
  lexer.tokens.add(Token(kind: kind, lexeme: lexeme, line: lexer.line,
          column: lexer.col - lexeme.len))


proc readToken(lexer: var Lexer) =
  print "Reading token at position: ", lexer.current

  if lexer.atEnd():
      return

  let c = lexer.advance()
  print "Character read: '", c, "'"
  case c
  of '(': lexer.addToken(tkBracketOpen)
  of ')': lexer.addToken(tkBracketClose)
  of '{': lexer.addToken(tkBraceOpen)
  of '}': lexer.addToken(tkBraceClose)
  of '[': lexer.addToken(tkSquareBracketOpen)
  of ']': lexer.addToken(tkSquareBracketClose)
  of '=': 
    if not lexer.atEnd() and lexer.source[lexer.current] == '=':
      discard lexer.advance() # ==
      lexer.addToken(tkOperator)
    else:
      lexer.addToken(tkEquals)
  of ':': lexer.addToken(tkSymbol)
  of ',': lexer.addToken(tkSymbol)
  of '!':
    if not lexer.atEnd() and lexer.source[lexer.current] == '=':
      discard lexer.advance() # !=
      lexer.addToken(tkOperator)
    else:
      lexer.addToken(tkOperator)
  of '<', '>':
    if not lexer.atEnd() and lexer.source[lexer.current] == '=':
        discard lexer.advance()
        lexer.addToken(tkOperator)
    else:
        lexer.addToken(tkOperator)
  of '+', '-', '*', '/', '%', '^', '.':
      if c == '/' and not lexer.atEnd():
          if lexer.source[lexer.current] == '/': # Single-line comment
              discard lexer.advance()
              while not lexer.atEnd() and lexer.source[lexer.current] != '\n':
                  discard lexer.advance()
              return # skip the token adding
          elif not lexer.atEnd() and lexer.source[lexer.current] == '*': # Multi-line comment
              discard lexer.advance()
              var nesting = 1
              while nesting > 0 and not lexer.atEnd():
                  if lexer.current + 1 < lexer.source.len:
                      if lexer.source[lexer.current] == '/' and lexer.source[lexer.current + 1] == '*':
                          nesting += 1
                          discard lexer.advance()
                      elif lexer.source[lexer.current] == '*' and lexer.source[lexer.current + 1] == '/':
                          nesting -= 1
                          discard lexer.advance()
                  discard lexer.advance()
              if not lexer.atEnd():
                  discard lexer.advance()
              return # skip the token adding
          else:
              lexer.addToken(tkOperator)
      else:
        if c == '.' and not lexer.atEnd() and lexer.source[lexer.current] == '.':
          discard lexer.advance()
          lexer.addToken(tkOperator)
        else:
          lexer.addToken(tkOperator)
  of ' ', '\r', '\t':
      discard
  of '\n':
      inc lexer.line
      lexer.col = 1
  else:
      # if c.isDigit:
      #     while not lexer.atEnd() and lexer.source[lexer.current].isDigit:
      #         discard lexer.advance()
      #     if not lexer.atEnd() and lexer.source[lexer.current] == '.':
      #         discard lexer.advance()
      #         while not lexer.atEnd() and lexer.source[lexer.current].isDigit:
      #             discard lexer.advance()
      #         lexer.addToken(tkFloat)
      #     else:
      #         lexer.addToken(tkInt)
      if c.isDigit:
          while not lexer.atEnd() and lexer.source[lexer.current].isDigit:
              discard lexer.advance()
          if not lexer.atEnd() and lexer.source[lexer.current] == '.':
              # range operator (..)
              if lexer.current + 1 < lexer.source.len and lexer.source[lexer.current + 1] == '.':
                  lexer.addToken(tkInt)
              else:
                  discard lexer.advance()
                  while not lexer.atEnd() and lexer.source[lexer.current].isDigit:
                      discard lexer.advance()
                  lexer.addToken(tkFloat)
          else:
              lexer.addToken(tkInt)
      elif c == '"':
          while not lexer.atEnd() and lexer.source[lexer.current] != '"':
              discard lexer.advance()
          if not lexer.atEnd():
              discard lexer.advance()
          lexer.addToken(tkString)
      elif c in ['{', '}']:
          lexer.addToken(tkSymbol)
      elif c.isAlphaAscii:
          while not lexer.atEnd() and (lexer.source[lexer.current].isAlphaNumeric or lexer.source[lexer.current] == '_'):
              discard lexer.advance()
          let lexeme = lexer.source[lexer.start..<lexer.current]
          #  "while", "for"
          if lexeme in ["var", "const", "if", "else", "elseif", "break", "fn", "return", "while", "break", "for", "in", "do"]:
              lexer.addToken(tkKeyword)
          elif lexeme in ["true", "false"]:
              lexer.addToken(tkBool)
          elif lexeme == "nil":
              lexer.addToken(tkNil)
          else:
              lexer.addToken(tkIdent)
      else:
          echo "Unrecognized char: ", c
          discard
  if lexer.tokens.len > 0:
      print "Token added: ", lexer.tokens[^1]

proc readTokens*(lexer: var Lexer): seq[Token] =
  print "Starting tokenization"
  while not lexer.atEnd():
      print "Current position: ", lexer.current, " / ", lexer.source.len
      lexer.start = lexer.current
      lexer.readToken()

  if lexer.tokens.len == 0 or lexer.tokens[^1].kind != tkEOF:
      lexer.tokens.add(Token(kind: tkEOF, lexeme: "", line: lexer.line, column: lexer.col))
  print "Tokenization complete. Total tokens: ", lexer.tokens.len
  result = lexer.tokens
