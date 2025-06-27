const std = @import("std");
const validate = @import("validate");
const ExpenseModel = @import("../models/expense.zig");

pub const ValidationResult = struct {
    valid: bool,
    errors_json: ?[]u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ValidationResult) void {
        if (self.errors_json) |json| {
            self.allocator.free(json);
        }
    }
};

var builder: ?validate.Builder(void) = null;
var expense_validator: ?*validate.Object(void) = null;

pub fn initValidators(allocator: std.mem.Allocator) !void {
    builder = try validate.Builder(void).init(allocator);

    const description_validator = builder.?.string(.{ .required = true, .min = 1, .max = 255 });
    const category_validator = builder.?.string(.{ .required = true, .min = 1, .max = 100 });
    const amount_validator = builder.?.float(f64, .{ .required = true, .min = 0.01 });
    const date_validator = builder.?.string(.{ .required = true, .min = 10, .max = 10 });

    expense_validator = builder.?.object(&.{
        builder.?.field("description", description_validator),
        builder.?.field("category", category_validator),
        builder.?.field("amount", amount_validator),
        builder.?.field("date", date_validator),
    }, .{});
}

pub fn deinitValidators(allocator: std.mem.Allocator) void {
    if (builder) |*b| {
        b.deinit(allocator);
        builder = null;
        expense_validator = null;
    }
}

pub fn validateExpenseRequest(allocator: std.mem.Allocator, expense_json: []const u8) !ValidationResult {
    if (expense_validator == null) {
        return ValidationResult{ .valid = false, .errors_json = null, .allocator = allocator };
    }

    var context = try validate.Context(void).init(allocator, .{ .max_errors = 20, .max_nesting = 4 }, {});
    defer context.deinit(allocator);

    _ = expense_validator.?.validateJsonS(expense_json, &context) catch |err| switch (err) {
        error.InvalidJson => {
            const error_json = try std.fmt.allocPrint(allocator, "{{\"errors\":[{{\"field\":\"json\",\"code\":0,\"err\":\"Invalid JSON format\"}}]}}", .{});
            return ValidationResult{ .valid = false, .errors_json = error_json, .allocator = allocator };
        },
        else => return err,
    };

    if (!context.isValid()) {
        const errors_json = try std.json.stringifyAlloc(allocator, context.errors(), .{ .emit_null_optional_fields = false });
        return ValidationResult{ .valid = false, .errors_json = errors_json, .allocator = allocator };
    }

    return ValidationResult{ .valid = true, .errors_json = null, .allocator = allocator };
}

pub fn validateExpenseRequestLegacy(expense: ExpenseModel.Expense.CreateRequest) bool {
    return expense.description.len > 0 and
        expense.category.len > 0 and
        expense.date.len > 0;
}
