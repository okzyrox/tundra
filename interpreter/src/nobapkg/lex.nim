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
    tkSymbol
    tkComment
    tkOperator
    tkBracketOpen
    tkBracketClose
    tkBraceOpen
    tkBraceClose
    tkEquals
    tkEOF

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
    let c = lexer.advance()
    print "Character read: '", c, "'"
    case c
    of '(': lexer.addToken(tkBracketOpen)
    of ')': lexer.addToken(tkBracketClose)
    of '{': lexer.addToken(tkBraceOpen)
    of '}': lexer.addToken(tkBraceClose)
    of '=': lexer.addToken(tkEquals)
    of ':': lexer.addToken(tkSymbol)
    of ',': lexer.addToken(tkSymbol)
    of '+', '-', '*', '/': lexer.addToken(tkOperator)
    of ' ', '\r', '\t': discard
    of '\n':
        inc lexer.line
        lexer.col = 1
    else:
        if c.isDigit:
            while lexer.current < lexer.source.len and lexer.source[
                    lexer.current].isDigit:
                discard lexer.advance()
            if lexer.current < lexer.source.len and lexer.source[lexer.current] == '.':
                discard lexer.advance()
                while lexer.current < lexer.source.len and lexer.source[
                        lexer.current].isDigit:
                    discard lexer.advance()
                lexer.addToken(tkFloat)
            else:
                lexer.addToken(tkInt)
        elif c == '"':
            while lexer.current < lexer.source.len and lexer.source[
                    lexer.current] != '"':
                discard lexer.advance()
            if lexer.current < lexer.source.len:
                discard lexer.advance()
            lexer.addToken(tkString)
        elif c in ['{', '}']:
            lexer.addToken(tkSymbol)
        elif c.isAlphaAscii:
            while lexer.current < lexer.source.len and (lexer.source[
                    lexer.current].isAlphaNumeric or lexer.source[lexer.current] == '_'):
                discard lexer.advance()
            let lexeme = lexer.source[lexer.start..<lexer.current]
            if lexeme in ["var", "const", "if", "else", "while", "for", "fn", "return"]:
                lexer.addToken(tkKeyword)
            else:
                lexer.addToken(tkIdent)
        else:
            echo "Unrecognized char: ", c
            discard
    print "Token added: ", lexer.tokens[^1]

proc readTokens*(lexer: var Lexer): seq[Token] =
    print "Starting tokenization"
    while not lexer.atEnd():
        print "Current position: ", lexer.current, " / ", lexer.source.len
        lexer.start = lexer.current
        lexer.readToken()

    lexer.tokens.add(Token(kind: tkEOF, lexeme: "", line: lexer.line,
            column: lexer.col))
    print "Tokenization complete. Total tokens: ", lexer.tokens.len
    result = lexer.tokens
