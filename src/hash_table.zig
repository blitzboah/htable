const std = @import("std");
const prime = @import("prime.zig");

const item = struct { key: []const u8, val: []const u8 };

const hash_table = struct { size: u8, count: u8, base_size: u8, items: []?*item };

const HT_PRIME_1 = 151;
const HT_PRIME_2 = 163;

const HT_INITIAL_BASE_SIZE = 53;

var HT_DELETED_ITEM = item{ .key = "", .val = "" };

pub fn ht_resize(allocator: std.mem.Allocator, ht: *hash_table, base_size: u8) std.mem.Allocator.Error!void {
    if (base_size < HT_INITIAL_BASE_SIZE) return;

    const new_ht = try ht_new_sized(allocator, base_size);

    for (0..ht.size) |i| {
        const ht_item = ht.items[i];
        if (ht_item != null and ht_item.? != &HT_DELETED_ITEM) {
            try ht_insert(allocator, new_ht, ht_item.?.key, ht_item.?.val);
        }
    }

    ht.base_size = new_ht.base_size;
    ht.count = new_ht.count;

    const tmp_size = ht.size;
    ht.size = new_ht.size;
    new_ht.size = tmp_size;

    const tmp_items = ht.items;
    ht.items = new_ht.items;
    new_ht.items = tmp_items;

    ht_delete_hash_table(allocator, new_ht);
}

pub fn ht_resize_up(allocator: std.mem.Allocator, ht: *hash_table) std.mem.Allocator.Error!void {
    const new_size = ht.base_size * 2;
    try ht_resize(allocator, ht, new_size);
}

pub fn ht_resize_down(allocator: std.mem.Allocator, ht: *hash_table) std.mem.Allocator.Error!void {
    const new_size = ht.base_size / 2;
    try ht_resize(allocator, ht, new_size);
}

pub fn ht_insert(allocator: std.mem.Allocator, ht: *hash_table, key: []const u8, val: []const u8) std.mem.Allocator.Error!void {
    const load = (@as(u16, ht.count) * 100) / ht.size;
    if (load > 70) {
        try ht_resize_up(allocator, ht);
    }

    const it = try ht_new_item(allocator, key, val);
    var index = ht_get_hash(it.key, ht.size, 0);
    var curr_item = ht.items[index];

    var i: u8 = 1;
    while (curr_item != null) {
        index = ht_get_hash(it.key, ht.size, i);
        curr_item = ht.items[index];
        i += 1;
    }

    ht.items[index] = it;
    ht.count += 1;
}

pub fn ht_search(ht: *hash_table, key: []const u8) ?[]const u8 {
    var index = ht_get_hash(key, ht.size, 0);
    var ht_item = ht.items[index];

    var i: u8 = 1;
    while (ht_item != null) {
        if (std.mem.eql(u8, ht_item.?.key, key)) {
            return ht_item.?.val;
        }
        index = ht_get_hash(key, ht.size, i);
        ht_item = ht.items[index];
        i += 1;
    }

    return null;
}

pub fn ht_delete(allocator: std.mem.Allocator, ht: *hash_table, key: []const u8) std.mem.Allocator.Error!void {
    const load = (@as(u16, ht.count) * 100) / ht.size;
    if (load < 10) {
        try ht_resize_down(allocator, ht);
    }
    var index = ht_get_hash(key, ht.size, 0);
    var ht_item = ht.items[index];

    var i: u8 = 1;
    while (ht_item != null) {
        if (ht_item.? != &HT_DELETED_ITEM) {
            if (std.mem.eql(u8, key, ht_item.?.key)) {
                ht_delete_item(allocator, ht_item.?);
                ht.items[index] = &HT_DELETED_ITEM;
            }
        }
        index = ht_get_hash(key, ht.size, i);
        ht_item = ht.items[index];
        i += 1;
    }

    ht.count -= 1;
}

pub fn ht_hash(s: []const u8, a: u8, m: u8) u8 {
    var hash: u64 = 0;
    const len_s = s.len;
    for (0..len_s) |j| {
        const power = std.math.powi(u32, a, @intCast(len_s - (j + 1))) catch 0;
        hash += @as(u64, power) * s[j];
        hash = @mod(hash, m);
    }
    return @intCast(hash);
}

pub fn ht_get_hash(s: []const u8, num_buckets: u8, attempt: u8) u8 {
    const hash_a = ht_hash(s, HT_PRIME_1, num_buckets);
    const hash_b = ht_hash(s, HT_PRIME_2, num_buckets);

    return (hash_a + (attempt * (hash_b + 1))) % num_buckets;
}

pub fn ht_new_item(allocator: std.mem.Allocator, k: []const u8, v: []const u8) !*item {
    var i = try allocator.create(item);

    i.key = try allocator.dupe(u8, k);
    i.val = try allocator.dupe(u8, v);

    return i;
}

pub fn ht_new_sized(allocator: std.mem.Allocator, base_size: u8) !*hash_table {
    var ht = try allocator.create(hash_table);
    ht.base_size = base_size;
    ht.size = @intCast(prime.next_prime(@as(i32, base_size)));
    ht.count = 0;
    ht.items = try allocator.alloc(?*item, ht.size);

    for (0..ht.size) |j| {
        ht.items[j] = null;
    }

    return ht;
}

pub fn ht_new(allocator: std.mem.Allocator) !*hash_table {
    return ht_new_sized(allocator, HT_INITIAL_BASE_SIZE);
}

pub fn ht_delete_item(allocator: std.mem.Allocator, item_ptr: *item) void {
    allocator.free(item_ptr.key);
    allocator.free(item_ptr.val);
    allocator.destroy(item_ptr);
}

pub fn ht_delete_hash_table(allocator: std.mem.Allocator, ht: *hash_table) void {
    for (0..ht.size) |i| {
        const ht_item = ht.items[i];
        if (ht_item != null and ht_item.? != &HT_DELETED_ITEM) {
            ht_delete_item(allocator, ht_item.?);
        }
    }
    allocator.free(ht.items);
    allocator.destroy(ht);
}
