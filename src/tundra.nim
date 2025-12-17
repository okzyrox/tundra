import tundrapkg/utils
import tundrapkg/lex
import tundrapkg/ast
import tundrapkg/parser
import tundrapkg/interpreter as interp

import std/[os, strutils, json]

proc run(filename: string, source: string) =
  print "Source code length: ", source.len
  var lexer = newLexer(source)
  let tokens = lexer.readTokens()
  print "Tokens read: ", tokens.len
  
  var parser = newParser(tokens)
  let ast = parser.parse()

  let astDump = ast.dumpJson()
  if not dirExists("dump"):
    createDir("dump")

  writeFile("dump/" & filename & ".json", $astDump.pretty())
  
  var interpreter = newInterpreter()
  interpreter.initializeGlobals()
  print "Globals initialized"
  interpreter.interpret(ast)
  
proc getVersion(): void =
  echo "-- Tundra Interpreter --"
  echo "Version: " & TUNDRA_VERSION
  echo "Commit: " & TUNDRA_COMMIT

proc tundra(file_path: string = "", version: bool = false): void =
  if file_path != "":
    if fileExists(file_path):
      let source = readFile(file_path)
      let path_name = file_path.replace(".td", "").replace("/", "_").replace("\\", "_")
      run(path_name, source)
    else:
      echo "File not found: ", file_path
  elif version:
    getVersion()
  else:
    echo "No file path provided. Use --help for more information."

when isMainModule:
  import cligen
  dispatch tundra, help = {"file_path": "The path to the file to run (.td extension)", "version": "Build version"}