fn main() {
    var w = 2 + 2
    var x = 5 - 2
    var y = 3 * 4
    var z = 4 / 2

    println(w) // 4
    println(x) // 5

    println(y) // 12
    println(z) // 2

    assert(w == 4, "Add. failed")
    assert(x == 3, "Sub. failed")
    assert(y == 12, "Mult. failed")
    assert(z == 2.0, "Div. failed")

    var m = 1 + 5 + 9
    println(m)
    assert(m == 15, "Chain addition failed")

    // Order of operations

    var a = 1 + 2 * 3
    println(a) 
    assert(a == 7, "Chain operations failed")

    // Negation

    var b = 9
    var negativeB = -b

    println(negativeB)
    assert(negativeB == -9, "Int negation failed")



}