const std = @import("std");

const item = struct { key: []const u8, val: []const u8 };

const hash_table = struct { size: u8, count: u8, items: []?*item };

const HT_DELETED_ITEM = item{ .key = null, .val = null };

pub fn ht_insert(allocator: std.mem.Allocator, ht: *hash_table, key: []const u8, val: []const u8) void {
    const it = try ht_new_item(allocator, key, val);
    var index = ht_get_hash(it.*.key, it.*.val, 0);
    const curr_item = ht.*.items[index];

    var i: u8 = 1;
    while (curr_item != null) {
        index = ht_get_hash(it.*.key, it.*.val, i);
        curr_item = ht.*.items[index];
        i += 1;
    }

    ht.*.items[index] = it;
    ht.*.count += 1;
}

pub fn ht_search(ht: *hash_table, key: []const u8) []const ?u8 {
    var index = ht_get_hash(key, ht.*.size, 0);
    const ht_item = ht.*.items[index];

    var i: u8 = 1;
    while (ht_item != null) {
        if (std.mem.eql([]const u8, ht_item.?.*.key, key))
            return ht_item.?.*.val;
        index = ht_get_hash(key, ht.*.size, i);
        ht_item = ht.*.items[index];
        i += 1;
    }

    return null;
}

pub fn ht_delete(allocator: std.mem.Allocator, ht: *hash_table, key: []const u8) void {
    var index = ht_get_hash(key, ht.*.size, 0);
    const ht_item = ht.*.items[index];

    var i: u8 = 1;
    while (ht_item != null) {
        if (ht_item.? != &HT_DELETED_ITEM) {
            if (std.mem.eql([]const u8, key, ht_item.?.*.key)) {
                ht_delete_item(allocator, &ht_item);
                ht.items[index] = &HT_DELETED_ITEM;
            }
        }
        index = ht_get_hash(key, ht.*.size, i);
        ht_item = ht.*.items[index];
        i += 1;
    }

    ht.count -= 1;
}

pub fn ht_hash(s: []const u8, a: u8, m: u16) u8 {
    var hash: u64 = 0;
    const len_s = s.len;
    for (0..len_s) |i| {
        const power = std.math.powi(u32, a, @intCast(len_s - (i + 1))) catch 0;
        hash += @as(u64, power) * s[i];
        hash = hash % m;
    }
    return @intCast(hash);
}

pub fn ht_get_hash(s: []const u8, num_buckets: u8, attempt: u8) u8 {
    const hash_a = ht_hash(s, 1, num_buckets);
    const hash_b = ht_hash(s, 28, num_buckets);

    return (hash_a + (attempt * (hash_b + 1))) % num_buckets;
}

pub fn ht_new_item(allocator: std.mem.Allocator, k: []const u8, v: []const u8) !*item {
    var i = try allocator.create(item);

    i.key = try allocator.dupe(u8, k);
    i.val = try allocator.dupe(u8, v);

    return i;
}

pub fn ht_new(allocator: std.mem.Allocator) !*hash_table {
    var ht = try allocator.create(hash_table);

    ht.size = 53;
    ht.count = 0;
    ht.items = try allocator.alloc(?*item, ht.size);

    for (0..ht.size) |i| {
        ht.items[i] = null;
    }

    return ht;
}

pub fn ht_delete_item(allocator: std.mem.Allocator, item_ptr: *item) void {
    allocator.free(item_ptr.key);
    allocator.free(item_ptr.val);
    allocator.destroy(item_ptr);
}

pub fn ht_delete_hash_table(allocator: std.mem.Allocator, ht: *hash_table) void {
    for (0..ht.size) |i| {
        const ht_item = ht.items[i];
        if (ht_item != null) {
            ht_delete_item(allocator, ht_item.?);
        }
    }
    allocator.free(ht.items);
    allocator.destroy(ht);
}
