var meta = {
    "name": "test"
}

fn getName(self: any) {
    return self["name"]
}

fn addHello(s: string) {
    return "Hello, " + s
}

fn main() {
    var x = "World"
    println(addHello(x))
    println(x.addHello())
    assert(x.addHello() == addHello(x), "Method call matching function call failed")

    var y = 123
    println(y.tofloat().typeof())
    assert(y.tofloat().typeof() == "float", "Method chain call failed")

    meta.getName().println() // i love this
    assert(meta.getName() == "test", "Method call on table failed")
}