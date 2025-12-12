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
    assert(result == 10, "Function using ifelse failed")

    // chain test

    var is_negative = test_num(-1)
    var is_zero = test_num(0)
    var is_positive = test_num(1)
    println(is_negative)
    println(is_zero)
    println(is_positive)

    assert(is_negative == "negative", "test_num negative failed")
    assert(is_zero == "zero", "test_num zero failed")
    assert(is_positive == "positive", "test_num positive failed")
    
    // scope test

    scopetest()

}