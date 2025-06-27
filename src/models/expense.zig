const std = @import("std");
const zqlite = @import("zqlite");

const Allocator = std.mem.Allocator;

// Core domain model for JSON serialization (no arena)
pub const ExpenseData = struct {
    id: usize,
    description: []const u8,
    amount: f64,
    category: []const u8,
    date: []const u8, // ISO format: YYYY-MM-DD
};

// Full expense with arena allocator
pub const Expense = struct {
    arena: std.heap.ArenaAllocator,
    data: ExpenseData,

    pub fn deinit(self: *Expense) void {
        self.arena.deinit();
    }

    pub fn getData(self: *const Expense) ExpenseData {
        return self.data;
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

            var arena = std.heap.ArenaAllocator.init(self.allocator);
            const arena_allocator = arena.allocator();

            const description = try arena_allocator.dupe(u8, expense_row.text(1));
            const category = try arena_allocator.dupe(u8, expense_row.text(3));
            const date = try arena_allocator.dupe(u8, expense_row.text(4));

            return Expense{
                .arena = arena,
                .data = ExpenseData{
                    .id = @intCast(expense_row.int(0)),
                    .description = description,
                    .amount = expense_row.float(2),
                    .category = category,
                    .date = date,
                },
            };
        }
        return null;
    }

    pub fn delete(self: *ExpenseRepository, id: usize) !bool {
        try self.conn.exec("DELETE FROM expenses WHERE id = ?", .{id});
        return self.conn.changes() > 0;
    }

    pub fn findAll(self: *ExpenseRepository) ![]Expense {
        var temp_arena = std.heap.ArenaAllocator.init(self.allocator);
        defer temp_arena.deinit();
        const temp_allocator = temp_arena.allocator();

        var expense_list = std.ArrayList(Expense).init(temp_allocator);
        var rows = try self.conn.rows("SELECT id, description, amount, category, date FROM expenses ORDER BY id", .{});
        defer rows.deinit();

        while (rows.next()) |expense_row| {
            var expense_arena = std.heap.ArenaAllocator.init(self.allocator);
            const expense_allocator = expense_arena.allocator();

            const description = try expense_allocator.dupe(u8, expense_row.text(1));
            const category = try expense_allocator.dupe(u8, expense_row.text(3));
            const date = try expense_allocator.dupe(u8, expense_row.text(4));

            try expense_list.append(Expense{
                .arena = expense_arena,
                .data = ExpenseData{
                    .id = @intCast(expense_row.int(0)),
                    .description = description,
                    .amount = expense_row.float(2),
                    .category = category,
                    .date = date,
                },
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
