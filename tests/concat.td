fn main() {
    var a = "Hello, "
    var b = "World!"
    var c = a + b
    var d = "Hi," + 1
    println(c)
    println(d)
    assert(c == "Hello, World!", "c should be 'Hello, World!'")
    assert(d == "Hi,1", "d should be 'Hi,1'")
}