const std = @import("std");
const zqlite = @import("zqlite");

const Allocator = std.mem.Allocator;

// Expense model with database operations
pub const Expense = struct {
    id: usize = 0,
    description: []const u8,
    amount: f64,
    category: []const u8,
    date: []const u8, // ISO format: YYYY-MM-DD

    pub const CreateRequest = struct {
        description: []const u8,
        amount: f64,
        category: []const u8,
        date: []const u8,
    };

    pub const Repository = struct {
        conn: *zqlite.Conn,
        allocator: Allocator,

        pub fn init(conn: *zqlite.Conn, allocator: Allocator) Repository {
            return .{
                .conn = conn,
                .allocator = allocator,
            };
        }

        pub fn create(self: *Repository, request: CreateRequest) !usize {
            try self.conn.exec("INSERT INTO expenses (description, amount, category, date) VALUES (?, ?, ?, ?)", .{ request.description, request.amount, request.category, request.date });
            return @intCast(self.conn.lastInsertedRowId());
        }

        pub fn findById(self: *Repository, id: usize) ?Expense {
            if (self.conn.row("SELECT id, description, amount, category, date FROM expenses WHERE id = ?", .{id}) catch null) |expense_row| {
                defer expense_row.deinit();
                return .{
                    .id = @intCast(expense_row.int(0)),
                    .description = expense_row.text(1),
                    .amount = expense_row.float(2),
                    .category = expense_row.text(3),
                    .date = expense_row.text(4),
                };
            }
            return null;
        }

        pub fn delete(self: *Repository, id: usize) bool {
            self.conn.exec("DELETE FROM expenses WHERE id = ?", .{id}) catch return false;
            return self.conn.changes() > 0;
        }

        pub fn findAll(self: *Repository) ![]Expense {
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

                try expense_list.append(.{
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

        pub fn getTotalAmount(self: *Repository) f64 {
            if (self.conn.row("SELECT COALESCE(SUM(amount), 0) FROM expenses", .{}) catch null) |total_row| {
                defer total_row.deinit();
                return total_row.float(0);
            }
            return 0.0;
        }

        pub fn getCount(self: *Repository) usize {
            if (self.conn.row("SELECT COUNT(*) FROM expenses", .{}) catch null) |count_row| {
                defer count_row.deinit();
                return @intCast(count_row.int(0));
            }
            return 0;
        }
    };
};
