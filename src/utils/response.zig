const std = @import("std");
const zap = @import("zap");
const ExpenseModel = @import("../models/expense.zig");
const SummaryModel = @import("../models/summary.zig");

pub const ApiResponse = struct {
    status: []const u8,
    message: []const u8,
    id: ?usize = null,
};

pub const ErrorResponse = struct {
    message: []const u8,
};

pub fn sendExpenseJson(request: zap.Request, expense_data: ExpenseModel.ExpenseData) !void {
    // Use stack buffer for zero-allocation hot path
    var response_buffer: [512]u8 = undefined;
    const json = try zap.util.stringifyBuf(&response_buffer, expense_data, .{});
    try request.sendJson(json);
}

pub fn sendSummaryJson(request: zap.Request, summary: SummaryModel.ExpenseSummaryResponse) !void {
    var response_buffer: [256]u8 = undefined;
    const json = try zap.util.stringifyBuf(&response_buffer, summary, .{});
    try request.sendJson(json);
}

pub fn sendApiResponse(request: zap.Request, status: zap.http.StatusCode, response: ApiResponse) !void {
    var response_buffer: [128]u8 = undefined;
    const json = try zap.util.stringifyBuf(&response_buffer, response, .{});
    request.setStatus(status);
    try request.sendJson(json);
}

pub fn sendError(request: zap.Request, status: zap.http.StatusCode, message: []const u8) !void {
    var response_buffer: [128]u8 = undefined;
    const error_response = ErrorResponse{ .message = message };
    const json = try zap.util.stringifyBuf(&response_buffer, error_response, .{});
    request.setStatus(status);
    try request.sendJson(json);
}

pub fn sendJsonResponse(request: zap.Request, status: zap.http.StatusCode, data: anytype) !void {
    var response_buffer: [512]u8 = undefined;
    const json = try zap.util.stringifyBuf(&response_buffer, data, .{});
    request.setStatus(status);
    try request.sendJson(json);
}

pub fn setCorsHeaders(request: zap.Request) !void {
    try request.setHeader("Access-Control-Allow-Origin", "*");
    try request.setHeader("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS");
    try request.setHeader("Access-Control-Allow-Headers", "Content-Type");
}
