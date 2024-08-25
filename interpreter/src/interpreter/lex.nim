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
    tkBracketOpen
    tkBracketClose
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

proc atEnd(self: Lexer): bool =
    self.current >= self.source.len

proc advance(self: var Lexer): char =
    print "advancing"
    result = self.source[self.current]
    inc self.current
    inc self.col

proc addToken(self: var Lexer, kind: TokenKind) =
    let lexeme = self.source[self.start..<self.current]
    self.tokens.add(Token(kind: kind, lexeme: lexeme, line: self.line,
            column: self.col - lexeme.len))


proc readToken(self: var Lexer) =
    echo "Reading token at position: ", self.current
    let c = self.advance()
    print "Character read: '", c, "'"
    case c
    of '(': self.addToken(tkBracketOpen)
    of ')': self.addToken(tkBracketClose)
    of ' ', '\r', '\t': discard
    of '\n':
        inc self.line
        self.col = 1
    else:
        if c.isDigit:
            while self.current < self.source.len and self.source[
                    self.current].isDigit:
                discard self.advance()
            if self.current < self.source.len and self.source[self.current] == '.':
                discard self.advance()
                while self.current < self.source.len and self.source[
                        self.current].isDigit:
                    discard self.advance()
                self.addToken(tkFloat)
            else:
                self.addToken(tkInt)
        elif c == '"':
            while self.current < self.source.len and self.source[
                    self.current] != '"':
                discard self.advance()
            if self.current < self.source.len:
                discard self.advance()
            self.addToken(tkString)
        elif c in ['{', '}']:
            self.addToken(tkSymbol)
        elif c.isAlphaAscii:
            while self.current < self.source.len and (self.source[
                    self.current].isAlphaNumeric or self.source[self.current] == '_'):
                discard self.advance()
            let lexeme = self.source[self.start..<self.current]
            if lexeme in ["var", "const", "if", "else", "while", "for", "fn", "return"]:
                self.addToken(tkKeyword)
            else:
                self.addToken(tkIdent)
        else:
            echo "Unrecognized char: ", c
            discard
    echo "Token added: ", self.tokens[^1]

proc readTokens*(self: var Lexer): seq[Token] =
    echo "Starting tokenization"
    while not self.atEnd():
        print "Current position: ", self.current, " / ", self.source.len
        self.start = self.current
        self.readToken()

    self.tokens.add(Token(kind: tkEOF, lexeme: "", line: self.line,
            column: self.col))
    echo "Tokenization complete. Total tokens: ", self.tokens.len
    result = self.tokens
