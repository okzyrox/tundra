var count = 0
fn fib(num1: int?, num2: int?, max: int) {
    if (num1 == nil) {
        num1 = 1
    }

    if (num2 == nil) {
        num2 = 0
    }

    if (count < max) {
        var newFibo = num1 + num2
        println(newFibo)
        var prev2 = num1
        var prev1 = newFibo
        count = count + 1
        fib(prev1, prev2, max)
    } else {
        return
    }
}

fn main() {
    // fib(1, 0, 10)
    fib(nil, nil, 10)
}