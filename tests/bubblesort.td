fn bubblesort(arr: any) {
    var unsorted = arr

    for (var i in 0 .. unsorted.len() - 1) {
        var swapped = false
        for (var j in 0 .. unsorted.len() - 1 - i - 1) {
            if (unsorted[j] > unsorted[j + 1]) {
                var temp = unsorted[j]
                unsorted[j] = unsorted[j + 1]
                unsorted[j + 1] = temp
                swapped = true
            }
        }
        if (!swapped) {
            break
        }
    }
    return unsorted
}

fn main() {
    var array = [64, 34, 25, 12, 22, 11, 90]
    var sorted = bubblesort(array)
    println("Unsorted: ", array)
    println("Sorted: ", sorted)
    assert(sorted == [11, 12, 22, 25, 34, 64, 90], "Bubblesort failed")
}