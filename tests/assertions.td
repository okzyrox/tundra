fn main() {
    var a = "Hi!"
    var b = 1
    var c = 3.14
    var d = 5 / 2
    var e = 5 

    println(a)
    println(b)
    println(c)
    println(d)
    assert(a == "Hi!", "String assertions failed")
    assert(b == 1, "Int assertions failed")
    assert(c == 3.14, "Float assertions failed")
    assert(d == 2.5, "Float division assertions failed")

}