fn main() {
    var x = 5
    println(tostring(x))
    x = x - 1
    println(tostring(x))

    assert(x == 4, "x should be 4 after sub")
}