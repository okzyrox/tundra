fn main() {
    var array = [1, 2, 3, 4, 5]
    for (var item in array) {
        println(item)
    }

    array.append(6)
    println(array)
    assert(array.len() == 6, "Array length after append failed")
    assert(array[5] == 6, "Array append value check failed")
}