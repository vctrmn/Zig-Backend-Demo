const std = @import("std");
const zap = @import("zap");
const ExpenseService = @import("../services/expense_service.zig").ExpenseService;
const ExpenseModel = @import("../models/expense.zig");
const validation = @import("../utils/validation.zig");
const response = @import("../utils/response.zig");

pub const ExpenseEndpoint = struct {
    path: []const u8,
    error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,
    service: *ExpenseService,

    pub fn init(path: []const u8, service: *ExpenseService) ExpenseEndpoint {
        return .{
            .path = path,
            .service = service,
        };
    }

    fn expenseIdFromPath(self: *ExpenseEndpoint, path: []const u8) ?usize {
        if (path.len >= self.path.len + 2) {
            if (path[self.path.len] != '/') return null;
            const id_str = path[self.path.len + 1 ..];
            return std.fmt.parseUnsigned(usize, id_str, 10) catch null;
        }
        return null;
    }

    pub fn get(self: *ExpenseEndpoint, request: zap.Request) !void {
        if (request.path) |path| {
            if (path.len == self.path.len) {
                return self.getAllExpenses(request);
            }
            if (self.expenseIdFromPath(path)) |id| {
                return self.getExpense(request, id);
            }
        }
        try self.getAllExpenses(request);
    }

    pub fn post(self: *ExpenseEndpoint, request: zap.Request) !void {
        try self.createExpense(request);
    }

    pub fn delete(self: *ExpenseEndpoint, request: zap.Request) !void {
        if (request.path) |path| {
            if (self.expenseIdFromPath(path)) |id| {
                return self.deleteExpense(request, id);
            }
        }
        try response.sendError(request, .bad_request, "Invalid expense ID");
    }

    pub fn put(_: *ExpenseEndpoint, request: zap.Request) !void {
        try response.sendError(request, .method_not_allowed, "Method not allowed");
    }

    pub fn patch(_: *ExpenseEndpoint, request: zap.Request) !void {
        try response.sendError(request, .method_not_allowed, "Method not allowed");
    }

    pub fn options(_: *ExpenseEndpoint, request: zap.Request) !void {
        try response.setCorsHeaders(request);
        request.setStatus(.no_content);
        request.markAsFinished(true);
    }

    pub fn head(_: *ExpenseEndpoint, request: zap.Request) !void {
        request.setStatus(.no_content);
        request.markAsFinished(true);
    }

    fn getExpense(self: *ExpenseEndpoint, request: zap.Request, id: usize) !void {
        if (self.service.getExpense(id)) |expense| {
            try response.sendExpenseJson(request, expense);
        } else {
            try response.sendError(request, .not_found, "Expense not found");
        }
    }

    fn getAllExpenses(self: *ExpenseEndpoint, request: zap.Request) !void {
        if (self.service.getExpensesAsJson()) |json| {
            defer self.service.allocator.free(json);
            try request.sendJson(json);
        } else |err| {
            std.debug.print("Error creating JSON: {}\n", .{err});
            try response.sendError(request, .internal_server_error, "Internal server error");
        }
    }

    fn createExpense(self: *ExpenseEndpoint, request: zap.Request) !void {
        const body = request.body orelse {
            try response.sendError(request, .bad_request, "Request body is required");
            return;
        };

        var validation_result = validation.validateExpenseRequest(self.service.allocator, body) catch {
            try response.sendError(request, .internal_server_error, "Validation error");
            return;
        };
        defer validation_result.deinit();

        if (!validation_result.valid) {
            if (validation_result.errors_json) |error_json| {
                request.setStatus(.bad_request);
                try request.setContentType(.JSON);
                try request.sendBody(error_json);
            } else {
                try response.sendError(request, .bad_request, "Validation failed");
            }
            return;
        }

        const parsed_expense = std.json.parseFromSlice(
            ExpenseModel.Expense.CreateRequest,
            self.service.allocator,
            body,
            .{},
        ) catch {
            try response.sendError(request, .bad_request, "Invalid JSON format");
            return;
        };
        defer parsed_expense.deinit();

        const expense_data = parsed_expense.value;

        if (self.service.createExpense(expense_data)) |id| {
            const api_response = response.ApiResponse{
                .status = "success",
                .message = "Expense added successfully",
                .id = id,
            };
            try response.sendApiResponse(request, .created, api_response);
        } else |err| {
            std.debug.print("Error adding expense: {}\n", .{err});
            try response.sendError(request, .internal_server_error, "Failed to add expense");
        }
    }

    fn deleteExpense(self: *ExpenseEndpoint, request: zap.Request, id: usize) !void {
        if (self.service.deleteExpense(id)) {
            const api_response = response.ApiResponse{
                .status = "success",
                .message = "Expense deleted successfully",
                .id = id,
            };
            try response.sendApiResponse(request, .ok, api_response);
        } else {
            const api_response = response.ApiResponse{
                .status = "error",
                .message = "Expense not found",
                .id = id,
            };
            try response.sendApiResponse(request, .not_found, api_response);
        }
    }
};
