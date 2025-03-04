fn add(a: int, b: int) {
    return a + b
}

fn main() {
    var w = 2 + 2
    var x = 5 - 2
    var y = 3 * 4
    var z = 4 / 2

    println(w) // 4
    println(x) // 5

    println(y) // 12
    println(z) // 2

    assert(w, 4, "w should be 4")
    assert(x, 3, "x should be 3")
    assert(y, 12, "y should be 12")
    assert(z, 2.0, "z should be 2.0")

    var n = add(1, 2)
    println(n)
    assert(n, 3, "n should be 3")

    var m = 1 + 5 + 9
    println(m)
    assert(m, 15, "m should be 15")

    // Order of operations

    var a = 1 + 2 * 3
    println(a) 
    assert(a, 7, "a should be 7")

    // Negation

    var b = 9
    var negativeB = -b

    println(negativeB)
    assert(negativeB, -9, "negativeB should be -9")

}