const std = @import("std");
const zap = @import("zap");
const SummaryService = @import("../services/summary_service.zig").SummaryService;
const response = @import("../utils/response.zig");

pub const SummaryEndpoint = struct {
    path: []const u8,
    error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,
    service: *SummaryService,

    pub fn init(path: []const u8, service: *SummaryService) SummaryEndpoint {
        return .{
            .path = path,
            .service = service,
        };
    }

    pub fn get(self: *SummaryEndpoint, request: zap.Request) !void {
        const summary = try self.service.getSummary();
        try response.sendSummaryJson(request, summary);
    }

    pub fn post(_: *SummaryEndpoint, request: zap.Request) !void {
        try response.sendError(request, .method_not_allowed, "Method not allowed");
    }
    pub fn put(_: *SummaryEndpoint, request: zap.Request) !void {
        try response.sendError(request, .method_not_allowed, "Method not allowed");
    }
    pub fn delete(_: *SummaryEndpoint, request: zap.Request) !void {
        try response.sendError(request, .method_not_allowed, "Method not allowed");
    }
    pub fn patch(_: *SummaryEndpoint, request: zap.Request) !void {
        try response.sendError(request, .method_not_allowed, "Method not allowed");
    }

    pub fn options(_: *SummaryEndpoint, request: zap.Request) !void {
        try response.setCorsHeaders(request);
        request.setStatus(.no_content);
        request.markAsFinished(true);
    }

    pub fn head(_: *SummaryEndpoint, request: zap.Request) !void {
        request.setStatus(.no_content);
        request.markAsFinished(true);
    }
};
