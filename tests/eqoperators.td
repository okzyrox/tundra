fn main() {
    // conditionary
    var a = 5
    var b = 5
    var c = 10
    
    println(a == b)  // true
    println(a == c)  // false
    println(a != c)  // true
    println(a != b)  // false
    
    var s1 = "hello"
    var s2 = "hello"
    var s3 = "world"
    
    println(s1 == s2)  // true
    println(s1 == s3)  // false
    println(s1 != s3)  // true

    assert(a == b, "Boolean equality failed")
    assert(a != c, "Boolean inequality failed")
    assert(!(a == c), "Boolean equality negation failed")
    assert(!(a != b), "Boolean inequality negation failed")

    assert(s1 == s2, "String equality failed")
    assert(s1 != s3, "String inequality failed")
    assert(!(s1 == s3), "String equality negation failed")

    var a = 5
    var b = 10
    
    if (a < b) {
        println("a is less than b")
    }
    
    if (!(a > b)) {
        println("a is not greater than b")
    }

    assert(a < b, "LT comp. failed")
    assert(!(a > b), "GT comp. negation failed")
    // comparitive

    var c = 5
    var d = 10

    println(c <= d)
    println(c >= d)
    println(c <= 5)
    println(c <= 6)
    println(c <= 4)

    assert(c <= d, "LToE less failed")
    assert(c <= 5, "LToE equal failed")
    assert(c <= 6, "LToE greater failed")
    assert(!(c <= 4), "LToE negation failed")
}