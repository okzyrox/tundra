// Note: this test is intentionally designed to fail, to show how type checking works
fn mult(a: int, b: int) {
    return a * b
}

fn main() {
    var a = mult(2, 3)

    // Intended to fail
    // var b = mult("hello", "world")
}