const std = @import("std");

pub fn is_prime(x: i32) i32 {
    if (x < 2) return -1;
    if (x < 4) return 1;
    if (@mod(x, 2) == 0) return 0;

    const sqrt_x = std.math.sqrt(@as(f64, @floatFromInt(x)));
    var i: f64 = 3;
    while (i <= sqrt_x) : (i += 2) {
        if (@mod(@as(f64, @floatFromInt(x)), i) == 0) {
            return 0;
        }
    }
    return 1;
}

pub fn next_prime(x: i32) i32 {
    var num = x;
    while (is_prime(num) != 1) {
        num += 1;
    }

    return num;
}
