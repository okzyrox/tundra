@echo off

nim c -d:release --opt:speed --app:console --out:bin\tundra.exe interpreter/src/tundra.nim