fn mult(a: int, b: int) {
    return a * b
}

fn main() {
    var a = mult(2, 3)

    assert(typeof("a") == "string", "Typeof string failed")
    assert(typeof(12) == "int", "Typeof int failed")
    assert(typeof(3.14) == "float", "Typeof float failed")
    assert(typeof(true) == "bool", "Typeof bool failed")
    assert(typeof(nil) == "nil", "Typeof nil failed")
    assert(typeof(main) == "function", "Typeof function failed")
}