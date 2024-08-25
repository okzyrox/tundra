# NB-LANG
"Not-Bad language"

An opionated theoretical language

File suffix: `.nb`, `.nbs`, `.noba`


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


Standard values:

- `true`
- `false`
- `nil`

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
In addition, each scope defined variable cannot be used outside the scope normally.

```c


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
- `int` (prefixable; e.g.: `int64`, `int32`, `int8`, default: int64)
- `float` (prefixable; e.g.: `float64`, `float32`, default: float64)
- `bool`
- `array`
- `table`
- `nil` a type and a value (in other words: `None`, `null`, `void`, `nothing`, `undefined`. Unassigned variables have this by default)

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


#### Other Operators

- `&` (string concatenation)
- `&&` (bitwise and)
- `||` (bitwise or)
- `!!` (bitwise not)

Operators are often performed in `if` statements, and can be used in other places as well.

```c
var a = 5
var b = 10
if (a > b) {
    println("a > b")
} else if (a < b) {
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
} else if (a == int and b == string) { // Evals to: `typeof(a) == int and typeof(b) == string`
    println("a is an int")
    println("b is a string")
} else if (a == int and b == int) { // Evals to: `typeof(a) == int and typeof(b) == int`
    println("They are both integers")
} else if (a == int or b == int) { // Evals to: `typeof(a) == int or typeof(b) == int`
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

### Strings/String concatenation

Strings can be concatenated, either using formatting with `$` or using the `&` operator.


### Functions

Functions are defined `scripts` of code that can be run by calling them.

There is no naming clause for functions. In addition, a function with the `nil` return type does not need to return anything.

```go

fn cube(x: int): int {
    return x * x * x
}

println(cube(5)) // >>> 125

```

`nil` function:

```go

fn say_hello() { // Equivalent to: fn say_hello(): nil {}
    println("Hello, World!")
}

say_hello() // >>> Hello, World!

var x = say_hello()
println(x) // >>> nil
println(say_hello()) // >>> nil

```

In addition, while usually functions names, like variable names, have to be unique. Functions can have repeated names aslong as they have different arguments.

```go

fn add(a: int, b: int): int {
    return a + b
}

fn add(a: string, b: string): string {
    return $"{a}{b}"
}

println(add(5, 10)) // >>> 15
println(add("hello", "world")) // >>> helloworld
println(add(5, "10")) // Error: no function called `add` with arguments `int` and `string`

```

If you want a function that can be called regardless of argument types then:

```go

fn say(output: any) {
    if ($output != nil) {
        println($output) // String conversion
    }
}

say("Hello, World!") // >>> Hello, World!
say(5) // >>> "5"
say(nil) // >>> "nil" // Nil still has a string representation; the function checks if it can be represented as a string
say(true) // >>> "true"

```

You also dont have to repeat type in function arguments when representing many arguments

```go

fn say(a, b: string) {
    println($"{a} {b}")
}

say("hello", "world") // >>> hello world
say("hello", 10) // Error: no function called `say` with arguments `string` and `int` | function called with incorrect argument types. Expected: `string`, `string`. got: `int`, `string`

```

Functions can also be defined similar to languages such as C or c++:

```go
fn add(a: int, b: int): int {
    return a + b
}

int sub(a: int, b: int) { // Automatically becomes: `fn sub(a: int, b: int): int { return a - b }`
    return a - b
}
```

For custom types, enums, and other things, you can create `symbol functions`

Symbol functions can only have 1 argument, being the object that they are called on.

```go

// Assuming a type called MyType, with a string field called name

fn '$'(x: MyType): string { // single quotes are used for symbol functions
    return x.name
}

var john = MyType { name: "John" }

println($john) // >>> "John"


```

### Classes

Classes are a way of representing objects or structures of groups of data or functions all in one.
(E.g. structs, objects, etc.)

To define a class, simply use:

```go

class Person {}

```

Adding fields to the class is just as simple, however:
- Each field needs a dedicated type definition

```go

class Person {
    var name: string
    var age: int
}
```

Classes can be constructed using brackets, but can have dedicated constructor methods as well.

```go

class Person {
    var name: string
    var age: int
}

var john = Person { name: "John", age: 30 }

println($"John is {john.age} years old") // >>> John is 30 years old

```

Also, notice how `var` is annotated after the fields? This is done to allow for the fields to be changed by sources outside the class itself.

For instance:


```go

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

```go

class Person {
    var name: string
    priv var age: int
}

fn new_person(name: string, age: int): Person {
    return Person { name: name, age: age }
}

var john = new_person("John", 30)

println($"{john.name}") // >>> John
println($"{john.age} years old") // Error: field `age` is private


// However, private fields can still be accessible by class functions.

```

#### Optional Fields

Optional fields are fields that can be left out, and are set to `nil` by default.

```go

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
println(john.get_age()) // >>> 30

john.set_age(31)

println(john.get_age()) // >>> 31

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

if (typeof(john) == Employee) { // typeof works with classes too
    println("John is an employee")
}


```



### Error catching


Errors can be caught using a standard `try` and `catch` syntax, each with scopes.

```go


try {
    println("Hello, World!")
    var a = 5
    a = a + "hello" // cannot concatenate int and string
} catch (e: StdError) { // `StdError` is a built-in error type, used for all standard issue errors.
    println($"Error: {e}") // >>> Error: cannot concatenate int and string
}



// Using functions

fn do_something(a: string) {
    a = a + 1 // cannot concatenate string and int
}

try do_something("hello") catch (e: StdError) {
    println($"Error: {e}") // >>> Error: cannot concatenate string and ints
}

```

Custom errors can be made too.

```go

const class MyError extends StdError {
    msg: "Something went wrong"
}

try {
    throw MyError()
} catch (e: MyError) {
    println($"Error: {e}") // >>> Error: Something went wrong
}


// Messages can also be specified in the `throw` part

try {
    throw MyError { msg: "Something maybe went wrong" }
} catch (e: MyError) {
    println($"Error: {e}") // >>> Error: Something maybe went wrong
}

```

In addition, different error types can be chained. While `StdError` covers all errors, you may want to use more specific error types for debugging.

```go

try {
    var a = 0
    a = a / 0 // throws: MathError -- MathError.DivideByZero

    var b = "hello"
    b = b / 2 // throws: OperatorError
} catch (e: MathError.DivideByZero) {
    println("Tried to divide by zero")
} catch (e: OperatorError) {
    println("Tried to use invalid operator on `string`")
} catch (e: StdError) { // Good to have a `StdError` catch at the end for any extra errors that arent prepared for.
    println($"Error: {e}")
}
```


### Loops

Loops can be used in NB.


#### For loop

```go

for (var i in 0..10) do { // Variable designed as a loop range of integers
    println(i)
} // >>> 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10


// Can also be done over arrays or tables

var strings = [
    "Hello",
    "World",
    "!"
]


for (var str in strings) do {
    println(str) // >>> Hello, World, !
}

var users = {
    john: { name: "John", age: 30 }, // Note the use of `:` to separate the key and value
    jack: { name: "Jack", age: 31 } // In addition, the key is a string type by default, but can be changed
}

for (var username, user in users) do { // Both fields of table specified
    println($"{username}: {user.name} is {user.age} years old") // >>> john: John is 30 years old ; jack: Jack is 31 years old
}


```


#### While Loop

While loops are similar to for loops, but they can only be used inside a `while` block and are often good for iterating a unknown amount of times.

```c

var running = true
var i = 0

while (running) do {
    println(i)

    if (i == 25) {
        running = false
    }

    i += 1
} // >>> 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, END


```


The `do` part of the while loop doesnt necessarily have to be a scope, but could be a function call instead.

```c

var i = 1

fn hello() {
    println($"Hello! x{i}")
    i += 1
}

while (i < 5) do hello() // >>> Hello! x1, Hello! x2, Hello! x3, Hello! x4, Hello! x5
// Note how the brackets are not included, this is optional

```

### Built-in functions/methods

There are various built in functions and methods that can be used.

#### Console

- `print()`  Prints to the console
- `println()`  Prints to the console with a newline at the end
- `read()`  Returns a string

#### Math

- `abs()`  Absolute value
- `sqrt()`  Square root
- `ceil()`  Rounds up
- `floor()`  Rounds down
- `round()`  Rounds to nearest integer
- `rand()`  Returns a random number
- `rand(a, b)`  Returns a random number in the range [a, b]
- `rand(int)`  Changeable for int32, int64, etc. Generates a random number for the specified type

#### String

- `$(x: any)`  String conversion
- `len()`  Returns the length of a string
- `lower()`  Converts a string to lowercase
- `upper()`  Converts a string to uppercase
- `trim()`  Removes leading and trailing whitespace
- `remove()`  Removes a substring from a string
- `replace()`  Replaces a substring in a string
- `splitby(x: string)`  Returns an array, the string is split by the specified string. If there are no matches, then the string is returned within the array

### Running

In order to run it, it needs a `main` function defined in the `main` module.

This can be done by defining the modulename code in the main script, and then creating a `main` function.

```cpp

@module main // This is optional depending on whether the filename is called `main.nb`. It is not required if the filename is `main.nb`

fn main() {
    println("Hello, World!")
}

```
