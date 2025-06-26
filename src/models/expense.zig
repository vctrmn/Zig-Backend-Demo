const std = @import("std");
const zqlite = @import("zqlite");

const Allocator = std.mem.Allocator;

// Core domain model
pub const Expense = struct {
    id: usize,
    description: []const u8,
    amount: f64,
    category: []const u8,
    date: []const u8, // ISO format: YYYY-MM-DD

    pub fn deinit(self: *const Expense, allocator: Allocator) void {
        allocator.free(self.description);
        allocator.free(self.category);
        allocator.free(self.date);
    }
};

// Request DTOs
pub const CreateExpenseRequest = struct {
    description: []const u8,
    amount: f64,
    category: []const u8,
    date: []const u8,
};

// Repository for database operations
pub const ExpenseRepository = struct {
    conn: *zqlite.Conn,
    allocator: Allocator,

    pub fn init(conn: *zqlite.Conn, allocator: Allocator) ExpenseRepository {
        return .{
            .conn = conn,
            .allocator = allocator,
        };
    }

    pub fn create(self: *ExpenseRepository, request: CreateExpenseRequest) !usize {
        try self.conn.exec("INSERT INTO expenses (description, amount, category, date) VALUES (?, ?, ?, ?)", .{ request.description, request.amount, request.category, request.date });
        return @intCast(self.conn.lastInsertedRowId());
    }

    pub fn findById(self: *ExpenseRepository, id: usize) !?Expense {
        if (self.conn.row("SELECT id, description, amount, category, date FROM expenses WHERE id = ?", .{id}) catch null) |expense_row| {
            defer expense_row.deinit();

            const description = try self.allocator.dupe(u8, expense_row.text(1));
            errdefer self.allocator.free(description);

            const category = try self.allocator.dupe(u8, expense_row.text(3));
            errdefer self.allocator.free(category);

            const date = try self.allocator.dupe(u8, expense_row.text(4));
            errdefer {
                self.allocator.free(description);
                self.allocator.free(category);
            }

            return Expense{
                .id = @intCast(expense_row.int(0)),
                .description = description,
                .amount = expense_row.float(2),
                .category = category,
                .date = date,
            };
        }
        return null;
    }

    pub fn delete(self: *ExpenseRepository, id: usize) !bool {
        try self.conn.exec("DELETE FROM expenses WHERE id = ?", .{id});
        return self.conn.changes() > 0;
    }

    pub fn findAll(self: *ExpenseRepository) ![]Expense {
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const arena_allocator = arena.allocator();

        var expense_list = std.ArrayList(Expense).init(arena_allocator);
        var rows = try self.conn.rows("SELECT id, description, amount, category, date FROM expenses ORDER BY id", .{});
        defer rows.deinit();

        while (rows.next()) |expense_row| {
            const description = try self.allocator.dupe(u8, expense_row.text(1));
            const category = try self.allocator.dupe(u8, expense_row.text(3));
            const date = try self.allocator.dupe(u8, expense_row.text(4));

            try expense_list.append(Expense{
                .id = @intCast(expense_row.int(0)),
                .description = description,
                .amount = expense_row.float(2),
                .category = category,
                .date = date,
            });
        }

        if (rows.err) |err| return err;
        return try self.allocator.dupe(Expense, expense_list.items);
    }

    pub fn getTotalAmount(self: *ExpenseRepository) !f64 {
        if (self.conn.row("SELECT COALESCE(SUM(amount), 0) FROM expenses", .{}) catch null) |total_row| {
            defer total_row.deinit();
            return total_row.float(0);
        }
        return 0.0;
    }

    pub fn getCount(self: *ExpenseRepository) !usize {
        if (self.conn.row("SELECT COUNT(*) FROM expenses", .{}) catch null) |count_row| {
            defer count_row.deinit();
            return @intCast(count_row.int(0));
        }
        return 0;
    }
};
