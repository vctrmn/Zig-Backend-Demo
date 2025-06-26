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
