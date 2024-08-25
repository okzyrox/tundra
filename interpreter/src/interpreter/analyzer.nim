## Semantic analysis stuff
##

import ast

import options

type
  Symbol = object
    name: string
    typ: string
    mutable: bool

  SymbolTable = seq[Symbol]

  SemanticAnalyzer = object
    symbolTable*: SymbolTable
    errors*: seq[string]

proc newSemanticAnalyzer*(): SemanticAnalyzer =
  SemanticAnalyzer(symbolTable: @[], errors: @[])

proc addSymbol(self: var SemanticAnalyzer, name: string, typ: string,
    mutable: bool) =
  self.symbolTable.add(Symbol(name: name, typ: typ, mutable: mutable))

proc addGlobalSymbol*(self: var SemanticAnalyzer, name: string, typ: string) =
  self.addSymbol(name, typ, false)

proc findSymbol(self: SemanticAnalyzer, name: string): Option[Symbol] =
  for symbol in self.symbolTable:
    if symbol.name == name:
      return some(symbol)
  return none(Symbol)

proc analyzeExpression(self: var SemanticAnalyzer, node: Node): string

proc analyzeLiteral(self: var SemanticAnalyzer, node: Node): string =
  node.literalType

proc analyzeIdentifier(self: var SemanticAnalyzer, node: Node): string =
  var symbol: Option[Symbol]
  if node.kind == nkIdentifier:
    symbol = self.findSymbol(node.identifierName)
  else:
    symbol = self.findSymbol(node.name)
  if symbol.isSome:
    return symbol.get.typ
  if node.kind == nkIdentifier:
    self.errors.add("Undefined variable: " & node.identifierName)
  else:
    self.errors.add("Undefined variable: " & node.name)
  return "error"

proc analyzeBinaryExpr(self: var SemanticAnalyzer, node: Node): string =
  let leftType = self.analyzeExpression(node.left)
  let rightType = self.analyzeExpression(node.right)
  if leftType != rightType:
    self.errors.add("Type mismatch in binary expression")
    return "error"
  return leftType

proc analyzeUnaryExpr(self: var SemanticAnalyzer, node: Node): string =
  self.analyzeExpression(node.operand)

proc analyzeExpression(self: var SemanticAnalyzer, node: Node): string =
  case node.kind
  of nkLiteral: return self.analyzeLiteral(node)
  of nkIdentifier: return self.analyzeIdentifier(node)
  of nkBinaryExpr: return self.analyzeBinaryExpr(node)
  of nkUnaryExpr: return self.analyzeUnaryExpr(node)
  else: return "error"

proc analyzeVarDecl(self: var SemanticAnalyzer, node: Node) =
  let valueType = self.analyzeExpression(node.value)
  if node.typ != "" and node.typ != valueType:
    self.errors.add("Type mismatch in variable declaration")
  self.addSymbol(node.name, if node.typ != "": node.typ else: valueType, true)

proc analyzeStatement(self: var SemanticAnalyzer, node: Node) =
  case node.kind
  of nkVarDecl: self.analyzeVarDecl(node)
  of nkExprStmt: discard self.analyzeExpression(node.expr)
  of nkFunctionDecl:
    self.addSymbol(node.fnName, "function", false)
  else: discard

proc analyze*(self: var SemanticAnalyzer, node: Node) =
  case node.kind
  of nkProgram:
    for statement in node.statements:
      self.analyzeStatement(statement)
  else:
    self.analyzeStatement(node)


proc addGlobals*(self: var SemanticAnalyzer) =
  self.addGlobalSymbol("println", "function")
