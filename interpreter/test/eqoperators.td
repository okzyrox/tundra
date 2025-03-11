fn main() {
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
}