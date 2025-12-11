fn main() {
    //  simple table
    var users = {
        "foo": "bar",
        "a": "abc"
    }
    
    println(users["foo"])  // barr
    println(users["a"])  // abc
    println(users["b"]) // nil (non-existent key)

    users["b"] = "def"
    println(users["b"]) // def

    // multi table
    var values = {
        "success": true,
        "code": 200,
        "message": "OK",
        "pi": 3.14
    }

    for (var key, value in values) {
        println(key, value)
    }

    // mixed table
    
    var mixedtable = {
        "hi": "hello",
        "count": 5,
        "valid": false,
        5: "xyz",
        6: "abc",
        7: "foobar"
    }

    for (var key, value in mixedtable) {
        println(key, value)
        println(typeof(key), typeof(value))
    }
}