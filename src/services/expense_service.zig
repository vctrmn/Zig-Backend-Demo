const std = @import("std");
const zqlite = @import("zqlite");
const ExpenseModel = @import("../models/expense.zig");

const Allocator = std.mem.Allocator;
const Expense = ExpenseModel.Expense;
const CreateExpenseRequest = ExpenseModel.CreateExpenseRequest;
const ExpenseRepository = ExpenseModel.ExpenseRepository;

pub const ExpenseService = struct {
    repository: ExpenseRepository,
    allocator: Allocator,
    lock: std.Thread.Mutex,

    pub fn init(conn: *zqlite.Conn, allocator: Allocator) ExpenseService {
        return .{
            .repository = ExpenseRepository.init(conn, allocator),
            .allocator = allocator,
            .lock = std.Thread.Mutex{},
        };
    }

    pub fn createExpense(self: *ExpenseService, request: CreateExpenseRequest) !usize {
        self.lock.lock();
        defer self.lock.unlock();
        return try self.repository.create(request);
    }

    pub fn getExpense(self: *ExpenseService, id: usize) !?Expense {
        return try self.repository.findById(id);
    }

    pub fn deleteExpense(self: *ExpenseService, id: usize) !bool {
        self.lock.lock();
        defer self.lock.unlock();
        return try self.repository.delete(id);
    }

    pub fn getAllExpenses(self: *ExpenseService) ![]Expense {
        self.lock.lock();
        defer self.lock.unlock();
        return try self.repository.findAll();
    }

    pub fn getExpensesAsJson(self: *ExpenseService) ![]const u8 {
        const expenses = try self.getAllExpenses();
        defer {
            for (expenses) |*expense| {
                expense.deinit();
            }
            self.allocator.free(expenses);
        }
        
        // Convert to ExpenseData for JSON serialization
        var expense_data_list = std.ArrayList(ExpenseModel.ExpenseData).init(self.allocator);
        defer expense_data_list.deinit();
        
        for (expenses) |*expense| {
            try expense_data_list.append(expense.getData());
        }
        
        return try std.json.stringifyAlloc(self.allocator, expense_data_list.items, .{});
    }

};
