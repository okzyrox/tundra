import tundrapkg/utils
import tundrapkg/lex
import tundrapkg/parser
import tundrapkg/analyzer
import tundrapkg/interpreter as interp

import os

const TUNDRA_VERSION {.strdefine.}: string = "0.0.1-alpha"
const TUNDRA_COMMIT {.strdefine.}: string = "0"


proc run(source: string) =
  print "Source code length: ", source.len
  var lexer = newLexer(source)
  print "Lexer created"
  let tokens = lexer.readTokens()
  print "Tokens read: ", tokens.len
  
  var parser = newParser(tokens)
  print "Parser created"
  let ast = parser.parse()
  print "AST created"
  
  var analyzer = newSemanticAnalyzer()
  print "Semantic analyzer created"
  analyzer.addGlobals()
  analyzer.analyze(ast)
  print "Semantic analysis complete"
  
  if analyzer.errors.len > 0:
    for error in analyzer.errors:
      echo "Semantic error: ", error
  else:
    var interpreter = newInterpreter()
    print "Interpreter created"
    interpreter.initializeGlobals()
    print "Globals initialized"
    interpreter.interpret(ast)
    print "Interpretation complete"
  
proc getVersion(): void =
  echo "-- Tundra Interpreter --"
  echo "Version: " & TUNDRA_VERSION
  echo "Commit: " & TUNDRA_COMMIT

proc main(file_path: string = "", version: bool = false): void =
  if file_path != "":
    if fileExists(file_path):
      let source = readFile(file_path)
      run(source)
    else:
      echo "File not found: ", file_path
  elif version:
    getVersion()
  else:
    echo "No file path provided. Use --help for more information."

when isMainModule:
  import cligen; dispatch main, help = {"file_path": "The path to the file to run (.td extension)",
  "version": "Build version"}