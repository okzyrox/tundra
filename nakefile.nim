import nake

import std/[options]

nake.validateShellCommands = true

const
  MainFile = "tundra.nim"
  ExeName = "tundra"
  DebugFeatures = "--out:" & ExeName & "_debug"
  ReleaseDir = "bin"
  ReleaseFeatures = "-d:release --opt:speed --app:console --out:bin\\" & ExeName

  SkippedTests = [
    "input"
  ]

# util; src nim forum
proc green*(s: string): string = "\e[32m" & s & "\e[0m"
proc grey*(s: string): string = "\e[90m" & s & "\e[0m"
proc yellow*(s: string): string = "\e[33m" & s & "\e[0m"
proc red*(s: string): string = "\e[31m" & s & "\e[0m"

proc getTundraExe(exeName: string): Option[string] = 
  var exe: string
  for pathComp, filePath in walkDir("."):
    if filePath.contains(exeName) and filePath.endsWith(".exe"):
      exe = filePath
      return some(exe)
  return none(string)

task "debug", "Build":
  shell(nimExe, "c", DebugFeatures, "-d:debug", "src/" & MainFile)

task "release", "Build release version":
  shell(nimExe, "c", ReleaseFeatures, "src/" & MainFile)

task "runTundraTests", "Run Tundra tests":
  var tundraExe = getTundraExe(ExeName)
  if tundraExe.isNone:
    tundraExe = getTundraExe(ExeName & "_debug")
  
  if tundraExe.isNone:
    echo "Tundra executable not found."
    quit(1)
  
  nake.validateShellCommands = false
  
  var tests: Table[string, string] # path; name
  var failedTests: seq[string] = @[]

  # get tests
  for pathComp, filePath in walkDir("tests/"):
    if filePath.endsWith(".td"):
      let testName = filePath.splitPath().tail.replace(".td", "")
      if testName in SkippedTests:
        continue
      tests[filePath] = testName
  # run tests
  for testPath, testName in tests.pairs:
    # silentShell will only show prints if we do have an error; good for debugging!!!
    let result = silentShell("", tundraExe.get(), "-f=" & testPath) 
    if result == false:
      echo red("Test failed: ") & testName
      failedTests.add(testName)
    else:
      echo green("Test passed: ") & testName

  if failedTests.len > 0:
    echo "Failed tests:"
    for failedTest in failedTests:
      echo "- " & failedTest
  
  var passedTests = tests.len - failedTests.len
  if passedTests == tests.len and passedTests > 0:
    echo green($passedTests & "/" & $tests.len & " passed.")
  elif passedTests == 0:
    echo red($passedTests & "/" & $tests.len & " passed.")
  else:
    echo yellow($passedTests & "/" & $tests.len & " passed.")