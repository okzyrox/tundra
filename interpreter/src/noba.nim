
import interpreter/utils
import interpreter/lex
import interpreter/parser
import interpreter/analyzer
import interpreter/interpreter as interp

const NOBA_VERSION {.strdefine.}:string = "0.0.1-alpha"
const NOBA_COMMIT {.strdefine.}:string = "0"


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
  echo "Version: " & NOBA_VERSION
  echo "Commit: " & NOBA_COMMIT

proc main(file_path: string = "", version: bool = false): void =
  if file_path != "":
    let source = readFile(file_path)
    run(source)
  elif version:
    getVersion()

when isMainModule:
  import cligen; dispatch main, help = {"file_path": "The path to the file to run (.noba extension)",
  "version": "Build version"}