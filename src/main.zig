const std = @import("std");
const ht = @import("hash_table.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const htb = try ht.ht_new(allocator);
    ht.ht_delete_hash_table(allocator, htb);
}
