const std = @import("std");
const zap = @import("zap");
const response = @import("../utils/response.zig");

pub const HealthEndpoint = struct {
    path: []const u8,
    error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

    pub fn init(path: []const u8) HealthEndpoint {
        return .{
            .path = path,
        };
    }

    pub fn get(_: *HealthEndpoint, request: zap.Request) !void {
        const health_response = struct {
            status: []const u8,
            timestamp: i64,
            service: []const u8,
        }{
            .status = "healthy",
            .timestamp = std.time.timestamp(),
            .service = "expenses-api",
        };

        try response.sendJsonResponse(request, .ok, health_response);
    }

    pub fn post(_: *HealthEndpoint, request: zap.Request) !void {
        try response.sendError(request, .method_not_allowed, "Method not allowed");
    }
    pub fn put(_: *HealthEndpoint, request: zap.Request) !void {
        try response.sendError(request, .method_not_allowed, "Method not allowed");
    }
    pub fn delete(_: *HealthEndpoint, request: zap.Request) !void {
        try response.sendError(request, .method_not_allowed, "Method not allowed");
    }
    pub fn patch(_: *HealthEndpoint, request: zap.Request) !void {
        try response.sendError(request, .method_not_allowed, "Method not allowed");
    }

    pub fn options(_: *HealthEndpoint, request: zap.Request) !void {
        try response.setCorsHeaders(request);
        request.setStatus(.no_content);
        request.markAsFinished(true);
    }

    pub fn head(_: *HealthEndpoint, request: zap.Request) !void {
        request.setStatus(.no_content);
        request.markAsFinished(true);
    }
};
