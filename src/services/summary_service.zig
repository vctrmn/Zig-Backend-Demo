const std = @import("std");
const zqlite = @import("zqlite");
const ExpenseModel = @import("../models/expense.zig");

const Allocator = std.mem.Allocator;
const ExpenseRepository = ExpenseModel.ExpenseRepository;

pub const ExpenseSummaryResponse = struct {
    total_expenses: f64,
    expense_count: usize,
    average_expense: f64,
};

pub const SummaryService = struct {
    repository: ExpenseRepository,
    allocator: Allocator,
    lock: std.Thread.Mutex,

    pub fn init(conn: *zqlite.Conn, allocator: Allocator) SummaryService {
        return .{
            .repository = ExpenseRepository.init(conn, allocator),
            .allocator = allocator,
            .lock = std.Thread.Mutex{},
        };
    }

    pub fn getSummary(self: *SummaryService) !ExpenseSummaryResponse {
        self.lock.lock();
        defer self.lock.unlock();

        const total_amount = try self.repository.getTotalAmount();
        const expense_count = try self.repository.getCount();

        return .{
            .total_expenses = total_amount,
            .expense_count = expense_count,
            .average_expense = if (expense_count > 0) total_amount / @as(f64, @floatFromInt(expense_count)) else 0.0,
        };
    }
};
