fn max(a: int, b: int) {
    if (a > b) {
        return a
    } else {
        return b
    }
}

fn test_num(n: int) {
    if (n < 0) {
        return "negative"
    } else if (n == 0) {
        return "zero"
    } else {
        return "positive"
    }
}

fn scopetest() {
    var a = 5
    var b = 10
    if (a < b) {
        var c = 15
        println(c)
    }
    //println(c) // error thrown here :)
}

fn main() {
    var result = max(10, 5)
    println(result)
    assert(result == 10, "result from `max(10, 5)` should be 10")

    // chain test

    var is_negative = test_num(-1)
    var is_zero = test_num(0)
    var is_positive = test_num(1)
    println(is_negative)
    println(is_zero)
    println(is_positive)

    assert(is_negative == "negative", "is_negative should be negative")
    assert(is_zero == "zero", "is_zero should be zero")
    assert(is_positive == "positive", "is_positive should be positive")
    
    // conditionary
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

    // scope test

    scopetest()

    // other ops

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