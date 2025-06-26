const std = @import("std");
const zqlite = @import("zqlite");

pub const DatabaseManager = struct {
    conn: zqlite.Conn,

    pub fn init() !DatabaseManager {
        const flags = zqlite.OpenFlags.Create | zqlite.OpenFlags.EXResCode;
        var conn = try zqlite.open("expenses.db", flags);

        try conn.exec(
            \\CREATE TABLE IF NOT EXISTS expenses (
            \\  id INTEGER PRIMARY KEY AUTOINCREMENT,
            \\  description TEXT NOT NULL,
            \\  amount REAL NOT NULL,
            \\  category TEXT NOT NULL,
            \\  date TEXT NOT NULL
            \\)
        , .{});

        return .{ .conn = conn };
    }

    pub fn deinit(self: *DatabaseManager) void {
        self.conn.close();
    }

    pub fn getConnection(self: *DatabaseManager) *zqlite.Conn {
        return &self.conn;
    }
};

// Database initialization callback (matches zqlite.Pool signature)
pub fn initializeDatabase(conn: zqlite.Conn, data: ?*anyopaque) !void {
    _ = data;
    try conn.exec(
        \\CREATE TABLE IF NOT EXISTS expenses (
        \\    id INTEGER PRIMARY KEY AUTOINCREMENT,
        \\    description TEXT NOT NULL,
        \\    amount REAL NOT NULL,
        \\    category TEXT NOT NULL,
        \\    date TEXT NOT NULL
        \\)
    , .{});
}

// Connection configuration callback (matches zqlite.Pool signature)
pub fn configureConnection(conn: zqlite.Conn, data: ?*anyopaque) !void {
    _ = data;
    try conn.exec("PRAGMA foreign_keys = ON", .{});
    try conn.exec("PRAGMA journal_mode = WAL", .{});
    try conn.exec("PRAGMA synchronous = NORMAL", .{});
    try conn.exec("PRAGMA cache_size = 10000", .{});
    try conn.exec("PRAGMA temp_store = MEMORY", .{});
}
