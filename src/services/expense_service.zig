const std = @import("std");
const zqlite = @import("zqlite");
const ExpenseModel = @import("../models/expense.zig");

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
        if (self.pool) |pool| {
            var conn = pool.acquire();
            defer conn.release();
            var repo = ExpenseRepository.init(&conn, self.allocator);
            return try repo.create(request);
        } else {
            return try self.repository.?.create(request);
        }
    }

    pub fn getExpense(self: *ExpenseService, id: usize) !?Expense {
        if (self.pool) |pool| {
            var conn = pool.acquire();
            defer conn.release();
            var repo = ExpenseRepository.init(&conn, self.allocator);
            return try repo.findById(id);
        } else {
            return try self.repository.?.findById(id);
        }
    }

    pub fn deleteExpense(self: *ExpenseService, id: usize) !bool {
        if (self.pool) |pool| {
            var conn = pool.acquire();
            defer conn.release();
            var repo = ExpenseRepository.init(&conn, self.allocator);
            return try repo.delete(id);
        } else {
            return try self.repository.?.delete(id);
        }
    }

    pub fn getAllExpenses(self: *ExpenseService) ![]Expense {
        if (self.pool) |pool| {
            var conn = pool.acquire();
            defer conn.release();
            var repo = ExpenseRepository.init(&conn, self.allocator);
            return try repo.findAll();
        } else {
            return try self.repository.?.findAll();
        }
    }

    pub fn getExpensesAsJson(self: *ExpenseService) ![]const u8 {
        // Use single arena for the entire JSON operation - more efficient
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const arena_allocator = arena.allocator();
        
        const expenses = try self.getAllExpenseDataDirect(arena_allocator);
        return try std.json.stringifyAlloc(self.allocator, expenses, .{});
    }
    
    // Direct ExpenseData extraction using single arena - optimal for JSON responses
    fn getAllExpenseDataDirect(self: *ExpenseService, arena_allocator: Allocator) ![]ExpenseModel.ExpenseData {
        var conn_value = if (self.pool) |pool| blk: {
            break :blk pool.acquire();
        } else self.repository.?.conn.*;
        const conn = if (self.pool) |_| &conn_value else self.repository.?.conn;
        
        if (self.pool != null) {
            defer conn_value.release();
        }
        
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
        return expense_data_list.items;
    }
    
    // Add cleanup method for ExpenseData arrays
    pub fn freeExpenseDataArray(self: *ExpenseService, expense_data: []ExpenseModel.ExpenseData) void {
        for (expense_data) |data| {
            self.allocator.free(data.description);
            self.allocator.free(data.category);
            self.allocator.free(data.date);
        }
        self.allocator.free(expense_data);
    }

};
