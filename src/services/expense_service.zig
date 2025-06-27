const std = @import("std");
const zqlite = @import("zqlite");
const ExpenseModel = @import("../models/expense.zig");
const ServiceBase = @import("base.zig");

const Allocator = std.mem.Allocator;
const Expense = ExpenseModel.Expense;
const CreateExpenseRequest = ExpenseModel.CreateExpenseRequest;
const ExpenseRepository = ExpenseModel.ExpenseRepository;

pub const ExpenseService = struct {
    pool: ?*zqlite.Pool = null,
    repository: ?ExpenseRepository = null,
    allocator: Allocator,

    pub fn init(conn: *zqlite.Conn, allocator: Allocator) ExpenseService {
        return .{
            .repository = ExpenseRepository.init(conn, allocator),
            .allocator = allocator,
        };
    }

    pub fn initWithPool(pool: *zqlite.Pool, allocator: Allocator) ExpenseService {
        return .{
            .pool = pool,
            .allocator = allocator,
        };
    }

    pub fn createExpense(self: *ExpenseService, request: CreateExpenseRequest) !usize {
        var service_conn = ServiceBase.ServiceConnection.init(self.pool, self.repository);
        defer service_conn.deinit();

        var repo = service_conn.getRepository(self.allocator);
        return try repo.create(request);
    }

    pub fn getExpense(self: *ExpenseService, id: usize) !?Expense {
        var service_conn = ServiceBase.ServiceConnection.init(self.pool, self.repository);
        defer service_conn.deinit();

        var repo = service_conn.getRepository(self.allocator);
        return try repo.findById(id);
    }

    pub fn deleteExpense(self: *ExpenseService, id: usize) !bool {
        var service_conn = ServiceBase.ServiceConnection.init(self.pool, self.repository);
        defer service_conn.deinit();

        var repo = service_conn.getRepository(self.allocator);
        return try repo.delete(id);
    }

    /// Get all expenses as JSON string
    /// This is the primary method for listing expenses in your REST API
    pub fn getExpensesAsJson(self: *ExpenseService) ![]const u8 {
        var service_conn = ServiceBase.ServiceConnection.init(self.pool, self.repository);
        defer service_conn.deinit();

        const conn = service_conn.getConn();

        // Use arena for temporary data during JSON creation
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const arena_allocator = arena.allocator();

        var expense_data_list = std.ArrayList(ExpenseModel.ExpenseData).init(arena_allocator);
        var rows = try conn.rows("SELECT id, description, amount, category, date FROM expenses ORDER BY id", .{});
        defer rows.deinit();

        while (rows.next()) |expense_row| {
            // Use arena allocator for all strings - single cleanup
            const description = try arena_allocator.dupe(u8, expense_row.text(1));
            const category = try arena_allocator.dupe(u8, expense_row.text(3));
            const date = try arena_allocator.dupe(u8, expense_row.text(4));

            try expense_data_list.append(ExpenseModel.ExpenseData{
                .id = @intCast(expense_row.int(0)),
                .description = description,
                .amount = expense_row.float(2),
                .category = category,
                .date = date,
            });
        }

        if (rows.err) |err| return err;

        // Convert to JSON using main allocator (caller must free)
        return try std.json.stringifyAlloc(self.allocator, expense_data_list.items, .{});
    }
};
