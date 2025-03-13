fn main() {
    // loopin!!
    var i = 0
    while (i < 5) {
        println(tostring(i))
        i = i + 1
    }
    println("After loop: " + tostring(i))
    assert(i == 5, "i should be 5 after loop")

    // loopin2

    var i = 0
    while (true) {
        println(tostring(i))
        i = i + 1
        if (i == 5) {
            break
        }
    }

    println("After loop: " + tostring(i))
    assert(i == 5, "i should be 5 after loop")

    var a = true
    var i = 0
    while (a == true) {
        println(tostring(i))
        i = i + 1
        if (i == 10000) {
            a = false
        }
    }

    assert(i == 10000, "i should be 10000 after loop")
}