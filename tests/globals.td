fn main() {
    println(_TUNDRA_VERSION)

    for (var globalName, globalVal in globals())  {
        println(globalName, globalVal)
    }
}