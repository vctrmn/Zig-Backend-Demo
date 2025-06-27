const std = @import("std");
const zap = @import("zap");
const response = @import("response.zig");

/// Standard method not allowed response for endpoints
pub fn handleMethodNotAllowed(request: zap.Request) !void {
    try response.sendError(request, .method_not_allowed, "Method not allowed");
}

/// Standard CORS options response for endpoints
pub fn handleOptions(request: zap.Request) !void {
    try response.setCorsHeaders(request);
    request.setStatus(.no_content);
    request.markAsFinished(true);
}

/// Standard HEAD response for endpoints
pub fn handleHead(request: zap.Request) !void {
    request.setStatus(.no_content);
    request.markAsFinished(true);
}

/// Parse ID from path like "/api/expenses/{id}"
pub fn parseIdFromPath(base_path: []const u8, path: []const u8) ?usize {
    if (path.len >= base_path.len + 2) {
        if (path[base_path.len] != '/') return null;
        const id_str = path[base_path.len + 1 ..];
        return std.fmt.parseUnsigned(usize, id_str, 10) catch null;
    }
    return null;
}

/// Handle service errors with appropriate HTTP status codes
pub fn handleServiceError(request: zap.Request, err: anyerror) !void {
    switch (err) {
        error.OutOfMemory => try response.sendError(request, .internal_server_error, "Out of memory"),
        error.InvalidInput => try response.sendError(request, .bad_request, "Invalid input"),
        error.NotFound => try response.sendError(request, .not_found, "Resource not found"),
        else => {
            std.log.err("Unexpected service error: {}", .{err});
            try response.sendError(request, .internal_server_error, "Internal server error");
        },
    }
}
