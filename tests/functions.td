function speak(person: string) {
    println("Hello, " + person + "!")
}

func add(a: int, b: int) {
    return a + b
}

fn main() {
    speak("John")
    speak("Jack")

    var x = add(1, 2)
    var y = 1 + 2
    println(x)
    println(y)

    assert(x == y, "Function return value failed")
}