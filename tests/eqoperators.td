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

    assert(a == b, "a should be equal to b")
    assert(a != c, "a should not be equal to c")
    assert(!(a == c), "a should not be equal to c")
    assert(!(a != b), "a should be equal to b")

    assert(s1 == s2, "s1 should be equal to s2")
    assert(s1 != s3, "s1 should not be equal to s3")
    assert(!(s1 == s3), "s1 should not be equal to s3")

    var a = 5
    var b = 10
    
    if (a < b) {
        println("a is less than b")
    }
    
    if (!(a > b)) {
        println("a is not greater than b")
    }

    assert(a < b, "a should be less than b")
    assert(!(a > b), "a should not be greater than b")

    // comparitive

    var c = 5
    var d = 10

    println(c <= d)
    println(c >= d)
    println(c <= 5)
    println(c <= 6)
    println(c <= 4)

    assert(c <= d, "c should be less than or equal to d")
    assert(c <= 5, "c should be less than or equal to 5")
    assert(c <= 6, "c should be less than or equal to 6")
    assert(!(c <= 4), "c should not be less than or equal to 4")
}