# NB-LANG
"Not-Bad language"

An opionated theoretical language

File suffix: `.nb`, `.nbs`


## Structure


### Keywords

The standard keywords list.

- `var`
- `const`
- `if`
- `else`
- `elseif`
- `while`
- `do`
- `for`
- `in`
- `not`
- `or`
- `and`
- `break`
- `continue`
- `return`
- `scope`
- `class`

- `fn`
- `func`
- `function`


- `pub`
- `priv`

Functions can also be defined similar to languages such as C or c++:

```c
fn add(a: int, b: int): int {
    return a + b
}

int sub(a: int, b: int) { // Automatically becomes: `fn sub(a: int, b: int): int { return a - b }`
    return a - b
}
```

### Variables

Variables are created using the keyword var, followed by the name of the variable.

```js
var text = "Hello, World!"
```

Variables can be reassigned using the assignment operator `=`, and can also be unassigned if a type is specified on creation.

```js
var text: string // Value: `nil`
text = "Hello, World!" // Value: `Hello, World!`
//...

var text: string
text = 5 // Invalid!

```

#### Constants

Constants are created using the keyword const, followed by the name of the constant.

Once a constant is defined, it cannot be changed.

```c

const VERSION = "1.0.0"

```

***Note**: typically, constant variable names are in full capital letters, but that isnt required.


Attempting to modify a constant will result in an error.

```c

const MY_NAME = "John Doe"

MY_NAME = "Jane Doe" // Error: cannot reassign to constant

```

Constants can be paired with other expressions to form `constant expressions`.

```c

const scope do_something {
    println("I did something!")
}

do_something // Prints: I did something!

do_something() // Prints: I did something!

do_something = {
    println("I did something else!")
} // Error: cannot reassign to constant

```


#### Public, Private

When using multiple files for your project, you may not want all features of a file accessible in a different file when accessing it.

This is where public and private annotations come in.


Say you have a file called `hello.nb`:
By default, any expressions in the file are public, but can be made private using the `priv` keyword.
`private` expessions can only be accessed in the same file.
```rust

priv fn say_hello() {
    println("Hello, World!")
}

pub fn hello() {
    say_hello() // Can access `say_hello`, as it is in the same file
}
// `fn hello() {}` would also evaluate to `pub fn hello() {}` however annotating `pub` and `priv` is good code practice.

```

Now in our main module (`main.nb`):

```c
import hello

fn main() {
    hello() // >>> Hello, World!

    say_hello() // Error: cannot access `say_hello`, as it is private
}

```


### Scopes

Scopes are defined by opening and closing curly brackets `{` and `}`.

Scopes are required for functions, loops and if statements, but can be specified in other areas of code for seperation and code cleanliness

```c
fn add(a: int, b: int): int { // Scope, with access to `a` and `b`
    return a + b
}

```

```c
In addition, each scope defined variable cannot be used outside the scope normally.

var a = 5
var b = 10

var scope = {
    var a = 6
    var b = 8
    println($"a = {a}") // >>> a = 6
    println($"b = {b}") // >>> b = 8
}

println($"a = {a}") // >>> a = 5
println($"b = {b}") // >>> b = 10
```

Any variables defined in a scope are automatically cleaned up once the final statement in the scope has been executed.


Scopes can also be functionally defined, and then called.

```c

scope do_something {
    println("I did something!")
}

scope do_something_else {
    println("I did something else!")
}

var a = 5
var b = 10

if (a > b) {
    do_something // scopes are `called` by accessing the variable name.
    // Alternatively, brackets can be used but it is optional:
    // e.g.: do_something()
} else {
    do_something_else
}
```


If you want to access specific outside variables, you can append brackets to the scope:
```c

var a = 5
var b = 10

scope do_something (a, b) { // This gives it the variables `a` and `b`
    println($"a = {a}") // >>> a = 5
    println($"b = {b}") // >>> b = 10    
}

do_something // >>> a = 5, b = 10

// Note, this isnt a function call, so you cant pass arguments to it.

do_something(5, 10)
// Error: Unexpected argument: `5`
// Error: Unexpected argument: `10`
// Error: Scope 'do_something' Expected 0 arguments, but got 2
```
### Basic Types

Standard basic types available by default are:

- `char`
- `string`
- `int` (prefixable; e.g.: `int64`, `int32`, `int8`)
- `float` (prefixable; e.g.: `float64`, `float32`)
- `bool`
- `array`
- `table`
- `nil` (in other words: `None`, `null`, `void`, `nothing`, `undefined`. Unassigned variables have this by default)

### Operators

#### Math Operators

- `+`
- `-`
- `*`
- `/`
- `%`
- `^`
and..

- `+=` (shorthand for: `a = a + b`)
- `-=` (shorthand for: `a = a - b`)
- `*=` (shorthand for: `a = a * b`)
- `/=` (shorthand for: `a = a / b`)
- `%=` (shorthand for: `a = a % b`)
- `^=` (shorthand for: `a = a ^ b`)


#### Comparison and Determination Operators

- `==`
- `!=`
- `>`
- `<`
- `>=`
- `<=`

Operators are often performed in `if` statements, and can be used in other places as well.

```c
var a = 5
var b = 10
if (a > b) {
    println("a > b")
} 
else if (a < b) {
    println("a < b")
} else {
    println("a == b")
}

```

You can also do `nil-checking` and type checking in if statements:

```c
var a = 5
var b = "10"
var c: int

if (a == string and b == int) { // Evals to: `typeof(a) == string and typeof(b) == int`
    println("a is a string")
    println("b is an int")
} elseif (a == int and b == string) { // Evals to: `typeof(a) == int and typeof(b) == string`
    println("a is an int")
    println("b is a string")
} elseif (a == int and b == int) { // Evals to: `typeof(a) == int and typeof(b) == int`
    println("They are both integers")
} elseif (a == int or b == int) { // Evals to: `typeof(a) == int or typeof(b) == int`
    println("One of them is an integer")
} else {
    println("I don't know what this is")
}

if (c == nil) {
    println($"c is {typeof(c)}") // >>> c is int
    println($"c = {c}") // >>> c = nil
}

```


### Modules

Modules are essentially groups of files, that can all be accessed by importing the module name, or directory name.

consider this file structure:

-> main.nb
-> hello.nb

VS

-> main.nb
-> greetings/
    -> hello.nb
    -> goodbye.nb
    -> mod.nb


For `mod.nb`, it simply initialises the module info and defines all the components


`mod.nb`

```go
import hello
import goodbye

export hello, goodbye // Used to `send` the imports back to `main.nb` when it imports `greetings`

//...
```

`hello.nb`
```go

pub fn hello() {
    println("Hello, World!")
}

```

`goodbye.nb`
```go

pub fn goodbye() {
    println("Goodbye!")
}

```

When importing from `main.nb`:

- Calling `import greetings.hello` will import the `hello` module from the `greetings` directory
- Calling `import greetings` will import the `mod.nb` file from the `greetings` directory, which imports `hello` and `goodbye`

Therefore:

```go
import greetings.hello // `greetings/hello.nb`

hello() // >>> Hello, World!
goodbye() // Error: Unknown function "goodbye"


```

```go
import greetings // `greetings/mod.nb`

hello() // >>> Hello, World!
goodbye() // >>> Goodbye!


```


### Classes

Classes are a way of representing objects or structures of groups of data or functions all in one.
(E.g. structs, objects, etc.)

To define a class, simply use:

```

class Person {}

```

Adding fields to the class is just as simple, however:
- Each field needs a dedicated type definition

```

class Person {
    var name: string
    var age: int
}
```

Classes can be constructed using brackets, but can have dedicated constructor methods as well.

```

class Person {
    var name: string
    var age: int
}

var john = Person { name: "John", age: 30 }

println($"John is {john.age} years old") // >>> John is 30 years old

```

Also, notice how `var` is annotated after the fields? This is done to allow for the fields to be changed by sources outside the class itself.

For instance:


```

class Person {
    id: int
    var name: string
}

var john = Person { id: 1, name: "John" }

john.name = "Jack"
john.id = 2 // Error: Cannot reassign to non-mutable field

```

Annotating `var` allows for mutability.


In addition, specified fields can be made optional or private.


#### Private fields

```

class Person {
    var name: string
    private var age: int
}

fn new_person(name: string, age: int): Person {
    return Person { name: name, age: age }
}

var john = new_person("John", 30)

println($"{john.name}) // >>> John
println($"{john.age} years old") // Error: field `age` is private


// However, private fields can still be accessible by class functions.

```

#### Optional Fields

Optional fields are fields that can be left out, and are set to `nil` by default.

```

class Person {
    var name: string
    var age: int? // `?` annotates optional fields
}

var john = Person { name: "John", age: 30 }
var jack = Person { name: "Jack" }

println($"{john.name} and {jack.name}") // >>> John and Jack
println($"{john.age} and {jack.age}") // >>> 30 and nil

```

#### Class Functions

Functions can be attached to classes, which automatically pass the class as a parameter to the function, and any other variables.

Functions for classes can be defined as:

```lua

class Person {
    var name: string
    var age: int
}

fn Person.new(name: string, age: int): Person {
    return Person { name: name, age: age }
}

fn Person.greet(person: Person) {
    println($"Hello, {person.name}!")
}

fn Person.get_age(person: Person): int {
    return person.age
}

fn Person.set_age(person: Person, age: int) { // Extra parameters are passed afterwards
    person.age = age
}

var john = Person.new("John", 30)

john.greet() // >>> Hello, John!
john.get_age() // >>> 30

john.set_age(31)

john.get_age() // >>> 31

```


#### Class Extending

Classes can be extended by other classes. Extended classes inherit the fields and methods of the extended class.

```rust

class Person {
    var name: string
    var age: int
}

fn Person.greet(person: Person) {
    println($"Hello, {person.name}!")
}

class Employee of Person {
    var years_worked: int
}

fn Employee.worked(employee: Employee) {
    println($"{person.name} worked for {person.years_worked} years!")
}

var john = Employee { name: "John", age: 30, years_worked: 5 }

john.greet() // >>> Hello, John!
john.worked() // >>> John worked for 5 years!


```

