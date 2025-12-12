fn main() {
    var a = "Hello, "
    var b = "World!"
    var c = a + b
    var d = "Hi," + 1
    println(c)
    println(d)
    assert(c == "Hello, World!", "String concatenation with string failed")
    assert(d == "Hi,1", "String concatenation with int failed")
}