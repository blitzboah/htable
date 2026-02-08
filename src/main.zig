const std = @import("std");
const ht = @import("hash_table.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const htb = try ht.ht_new(allocator);
    defer ht.ht_delete_hash_table(allocator, htb);

    // test insert
    try ht.ht_insert(allocator, htb, "hello", "world");
    try ht.ht_insert(allocator, htb, "foo", "bar");
    try ht.ht_insert(allocator, htb, "key", "value");

    std.debug.print("inserted 3 items\n", .{});

    // test search
    if (ht.ht_search(htb, "hello")) |val| {
        std.debug.print("found 'hello': {s}\n", .{val});
    } else {
        std.debug.print("'hello' not found\n", .{});
    }

    if (ht.ht_search(htb, "foo")) |val| {
        std.debug.print("found 'foo': {s}\n", .{val});
    } else {
        std.debug.print("'foo' not found\n", .{});
    }

    if (ht.ht_search(htb, "notfound")) |val| {
        std.debug.print("found 'notfound': {s}\n", .{val});
    } else {
        std.debug.print("'notfound' not found\n", .{});
    }

    // test delete
    try ht.ht_delete(allocator, htb, "foo");
    std.debug.print("deleted 'foo'\n", .{});

    if (ht.ht_search(htb, "foo")) |val| {
        std.debug.print("found 'foo': {s}\n", .{val});
    } else {
        std.debug.print("'foo' not found after delete\n", .{});
    }

    std.debug.print("count: {}\n", .{htb.count});
}
