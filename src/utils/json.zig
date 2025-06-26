const std = @import("std");

pub fn parseJsonFromSlice(comptime T: type, allocator: std.mem.Allocator, slice: []const u8) !std.json.Parsed(T) {
    return std.json.parseFromSlice(T, allocator, slice, .{});
}

pub fn stringifyAlloc(allocator: std.mem.Allocator, value: anytype) ![]const u8 {
    return std.json.stringifyAlloc(allocator, value, .{});
}

pub fn stringifyBuf(buf: []u8, value: anytype) ![]const u8 {
    var stream = std.io.fixedBufferStream(buf);
    try std.json.stringify(value, .{}, stream.writer());
    return stream.getWritten();
}
