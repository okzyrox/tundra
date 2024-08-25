import interpreter/utils
import interpreter/lex
import interpreter/parser
import interpreter/analyzer
import interpreter/interpreter as interp

proc run(source: string) =
  echo "Source code length: ", source.len
  var lexer = newLexer(source)
  print "Lexer created"
  let tokens = lexer.readTokens()
  echo "Tokens read: ", tokens.len
  
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
    echo "Interpretation complete"

when isMainModule:
  print "Reading"
  let source = readFile("hello.noba")
  print "Source file read, content:"
  echo source
  print "Running"
  run(source)