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

    // L AND
    var c = true && false
    println(c)
    assert(c == false, "Logical AND failed")
    assert(true && true == true, "Logical AND failed (2)")

    var ci = 1 && 0
    println(ci)
    assert(ci == false, "Logical AND with ints failed")
    assert(1 && 1 == true, "Logical AND with ints failed (2)")

    // L OR
    var d = true || false
    println(d)
    assert(d == true, "Logical OR failed")
    assert(false || false == false, "Logical OR failed (2)")

    var di = 0 || 1
    println(di)
    assert(di == true, "Logical OR with ints failed")
    assert(0 || 0 == false, "Logical OR with ints failed (2)")
    
}