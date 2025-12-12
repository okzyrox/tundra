## Semantic analysis stuff
##
import std/[options]

import ast

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

proc addSymbol(analyzer: var SemanticAnalyzer, name: string, typ: string,
    mutable: bool) =
  analyzer.symbolTable.add(Symbol(name: name, typ: typ, mutable: mutable))

proc addGlobalSymbol*(analyzer: var SemanticAnalyzer, name: string, typ: string) =
  analyzer.addSymbol(name, typ, false)

proc findSymbol(analyzer: SemanticAnalyzer, name: string): Option[Symbol] =
  for symbol in analyzer.symbolTable:
    if symbol.name == name:
      return some(symbol)
  return none(Symbol)

proc analyzeExpression(analyzer: var SemanticAnalyzer, node: Node): string

proc analyzeLiteral(analyzer: var SemanticAnalyzer, node: Node): string =
  node.literalType

proc analyzeIdentifier(analyzer: var SemanticAnalyzer, node: Node): string =
  var symbol: Option[Symbol]
  if node.kind == nkIdentifier:
    symbol = analyzer.findSymbol(node.identifierName)
  else:
    symbol = analyzer.findSymbol(node.name)
  if symbol.isSome:
    return symbol.get.typ
  if node.kind == nkIdentifier:
    analyzer.errors.add("Undefined variable: " & node.identifierName)
  else:
    analyzer.errors.add("Undefined variable: " & node.name)
  return "error"

proc analyzeBinaryExpr(analyzer: var SemanticAnalyzer, node: Node): string =
  let leftType = analyzer.analyzeExpression(node.left)
  let rightType = analyzer.analyzeExpression(node.right)
  if node.left.kind == nkLiteral or node.right.kind == nkLiteral and (node.left.kind == nkIdentifier or node.right.kind == nkIdentifier):
    return leftType
  elif leftType != rightType:
    # echo node.left.identifierName & " " & node.operator & " " & node.right.identifierName
    # echo leftType & " " & rightType
    analyzer.errors.add("Type mismatch in binary expression")
    return "error"
  return leftType

proc analyzeUnaryExpr(analyzer: var SemanticAnalyzer, node: Node): string =
  analyzer.analyzeExpression(node.operand)

proc analyzeExpression(analyzer: var SemanticAnalyzer, node: Node): string =
  case node.kind
  of nkLiteral: return analyzer.analyzeLiteral(node)
  of nkIdentifier: return analyzer.analyzeIdentifier(node)
  of nkBinaryExpr: return analyzer.analyzeBinaryExpr(node)
  of nkUnaryExpr: return analyzer.analyzeUnaryExpr(node)
  else: return "error"

proc analyzeVarDecl(analyzer: var SemanticAnalyzer, node: Node) =
  let valueType = analyzer.analyzeExpression(node.value)
  if node.typ != "" and node.typ != valueType:
    analyzer.errors.add("Type mismatch in variable declaration")
  analyzer.addSymbol(node.name, if node.typ != "": node.typ else: valueType, true)

proc analyzeStatement(analyzer: var SemanticAnalyzer, node: Node) =
  case node.kind
  of nkVarDecl: analyzer.analyzeVarDecl(node)
  of nkExprStmt: discard analyzer.analyzeExpression(node.expr)
  of nkFunctionDecl:
    analyzer.addSymbol(node.fnName, "function", false)
  else: discard

proc analyze*(analyzer: var SemanticAnalyzer, node: Node) =
  case node.kind
  of nkProgram:
    for statement in node.statements:
      analyzer.analyzeStatement(statement)
  else:
    analyzer.analyzeStatement(node)


proc addGlobals*(analyzer: var SemanticAnalyzer) =
  analyzer.addGlobalSymbol("println", "function")
