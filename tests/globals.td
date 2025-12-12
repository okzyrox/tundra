fn main() {
    println(_TUNDRA_VERSION)
    println(_TUNDRA_COMMIT)

    for (var globalName, globalVal in globals())  {
        println(globalName, globalVal)
    }
}