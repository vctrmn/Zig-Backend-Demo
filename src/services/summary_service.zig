const std = @import("std");
const zqlite = @import("zqlite");
const ExpenseModel = @import("../models/expense.zig");
const SummaryModel = @import("../models/summary.zig");
const ServiceBase = @import("base.zig");

const Allocator = std.mem.Allocator;
const ExpenseRepository = ExpenseModel.ExpenseRepository;

pub const SummaryService = struct {
    pool: ?*zqlite.Pool = null,
    repository: ?ExpenseRepository = null,
    allocator: Allocator,

    pub fn init(conn: *zqlite.Conn, allocator: Allocator) SummaryService {
        return .{
            .repository = ExpenseRepository.init(conn, allocator),
            .allocator = allocator,
        };
    }

    pub fn initWithPool(pool: *zqlite.Pool, allocator: Allocator) SummaryService {
        return .{
            .pool = pool,
            .allocator = allocator,
        };
    }

    pub fn getSummary(self: *SummaryService) !SummaryModel.ExpenseSummaryResponse {
        var service_conn = ServiceBase.ServiceConnection.init(self.pool, self.repository);
        defer service_conn.deinit();

        var repo = service_conn.getRepository(self.allocator);

        const total_amount = try repo.getTotalAmount();
        const expense_count = try repo.getCount();

        return .{
            .total_expenses = total_amount,
            .expense_count = expense_count,
            .average_expense = if (expense_count > 0)
                total_amount / @as(f64, @floatFromInt(expense_count))
            else
                0.0,
        };
    }
};
