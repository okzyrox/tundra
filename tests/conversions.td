// Conversions

fn main() {
    var nums = 1234
    var floats = 1234.02
    var str_from_num = tostring(nums)
    var str_from_float = tostring(floats)

    println(str_from_num, typeof(str_from_num))
    println(str_from_float, typeof(str_from_float))

    var num_from_str = toint("5678")
    var float_from_str = tofloat("5678.99")
    println(num_from_str, typeof(num_from_str))
    println(float_from_str, typeof(float_from_str))
    
    assert(str_from_num == "1234", "String conversion from int failed")
    assert(str_from_float == "1234.02", "String conversion from float failed")
    assert(num_from_str == 5678, "Int conversion from string failed")
    assert(float_from_str == 5678.99, "Float conversion from string failed")
}