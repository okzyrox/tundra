fn main() {
    var array = [1, 2, 3, 4, 5]
    for (var item in array) {
        println(item)
    }

    assert(array.len() == 5, "Array length check failed")
    assert(array[0] == 1, "Array index check failed")

    array.append(6)
    println(array)
    assert(array.len() == 6, "Array length after append failed")
    assert(array[5] == 6, "Array append value check failed")

    var matrix = [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
    ]

    println(matrix)
    for (var i in 0 .. matrix.len() - 1) {
        for (var j in 0 .. matrix[i].len() - 1) {
            println("matrix[", i, "][", j, "] = ", matrix[i][j])
        }
    }

    assert(matrix[1][1] == 5, "Matrix value check failed")
    assert(matrix.len() == 3, "Matrix row count check failed")
    assert(matrix[0].len() == 3, "Matrix column count check failed")

    var arr = [1, 2, 3, 4, 5]
    var slice = arr[1..3] // 2, 3, 4
    println(slice)

    assert(slice.len() == 3, "Array slice length check failed")
    assert(slice == [2, 3, 4], "Array slice value check failed")
}