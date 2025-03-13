fn main() {
    var x = 5
    println(tostring(x))
    x = x - 1
    println(tostring(x))

    assert(x == 4, "x should be 4 after sub")

    var a = 6
    var b = 7

    b = b - a
    println(tostring(b))

    assert(b == 1, "b should be 1 after sub")

    var n = 4
    var m = 5
    var o = 0
    o = o + m + n

    println(o)
    assert(o == 9, "o should equal 9 after add")
}