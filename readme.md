# Tundra

an uninteresting and uninspiring interpreted programming language with aspects from Nim, Lua and Rust

i was tired and thought "hey this would be cool ngl" and then i did it

## How to run?

### Requirements:

- #### Nim 2.2.2+ 
    - (may work on older versions)
- #### Nimble Packages:
    - `cligen` 1.7.3+
    - `nake` 1.9.5+

### Compilation
Tundra uses **Nake**, so install Nake and run either:
- `nake debug`, for ***debug*** builds

- `nake release` for ***release*** builds

### Usage

```sh

# or tundra_debug
tundra -f=filename.td

```

### Testing
Also using Nake again, run:
- `nake runTundraTests`

## Extras

### Code Highlighting

- [**vscode**](https://github.com/okzyrox/tundra/tree/main/extensions/vscode/)

### "Writeup"

read at: [**writeup**](https://github.com/okzyrox/tundra/blob/main/2am-writeup.md)