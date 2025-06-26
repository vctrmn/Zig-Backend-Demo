const std = @import("std");
const zqlite = @import("zqlite");
const ExpenseModel = @import("../models/expense.zig");

const Allocator = std.mem.Allocator;

pub const ExpenseService = struct {
    repository: ExpenseModel.Expense.Repository,
    allocator: Allocator,
    lock: std.Thread.Mutex,

    pub fn init(conn: *zqlite.Conn, allocator: Allocator) ExpenseService {
        return .{
            .repository = ExpenseModel.Expense.Repository.init(conn, allocator),
            .allocator = allocator,
            .lock = std.Thread.Mutex{},
        };
    }

    pub fn createExpense(self: *ExpenseService, request: ExpenseModel.Expense.CreateRequest) !usize {
        self.lock.lock();
        defer self.lock.unlock();
        return try self.repository.create(request);
    }

    pub fn getExpense(self: *ExpenseService, id: usize) ?ExpenseModel.Expense {
        return self.repository.findById(id);
    }

    pub fn deleteExpense(self: *ExpenseService, id: usize) bool {
        self.lock.lock();
        defer self.lock.unlock();
        return self.repository.delete(id);
    }

    pub fn getAllExpenses(self: *ExpenseService) ![]ExpenseModel.Expense {
        self.lock.lock();
        defer self.lock.unlock();
        return try self.repository.findAll();
    }

    pub fn getExpensesAsJson(self: *ExpenseService) ![]const u8 {
        const expenses = try self.getAllExpenses();
        defer {
            for (expenses) |expense| {
                self.allocator.free(expense.description);
                self.allocator.free(expense.category);
                self.allocator.free(expense.date);
            }
            self.allocator.free(expenses);
        }
        return try std.json.stringifyAlloc(self.allocator, expenses, .{});
    }

};
