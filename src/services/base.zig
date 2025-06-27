const std = @import("std");
const zqlite = @import("zqlite");
const ExpenseModel = @import("../models/expense.zig");

const Allocator = std.mem.Allocator;
const ExpenseRepository = ExpenseModel.ExpenseRepository;

/// Common database connection management for services
pub const ServiceConnection = struct {
    conn: zqlite.Conn,
    is_from_pool: bool,

    pub fn init(pool: ?*zqlite.Pool, repository: ?ExpenseRepository) ServiceConnection {
        if (pool) |p| {
            return .{
                .conn = p.acquire(),
                .is_from_pool = true,
            };
        } else {
            return .{
                .conn = repository.?.conn.*,
                .is_from_pool = false,
            };
        }
    }

    pub fn deinit(self: *ServiceConnection) void {
        if (self.is_from_pool) {
            self.conn.release();
        }
    }

    pub fn getConn(self: *ServiceConnection) *zqlite.Conn {
        return &self.conn;
    }

    pub fn getRepository(self: *ServiceConnection, allocator: Allocator) ExpenseRepository {
        return ExpenseRepository.init(self.getConn(), allocator);
    }
};
