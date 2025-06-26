const std = @import("std");

const Allocator = std.mem.Allocator;

// Input sanitization for security
pub const SanitizationError = error{
    InvalidInput,
    InputTooLong,
    ContainsSQLKeywords,
    ContainsHtmlTags,
};

const MAX_STRING_LENGTH = 1000;
const MAX_DESCRIPTION_LENGTH = 500;

// SQL keywords to block (basic protection)
const SQL_KEYWORDS = [_][]const u8{
    "SELECT", "INSERT", "UPDATE", "DELETE", "DROP", "CREATE", "ALTER",
    "EXEC", "EXECUTE", "UNION", "SCRIPT", "JAVASCRIPT", "VBSCRIPT",
    "ONLOAD", "ONERROR", "ONCLICK", "<SCRIPT>", "</SCRIPT>",
};

pub fn sanitizeString(allocator: Allocator, input: []const u8, max_length: usize) ![]const u8 {
    if (input.len == 0) {
        return error.InvalidInput;
    }
    
    if (input.len > max_length) {
        return error.InputTooLong;
    }
    
    // Check for SQL injection patterns
    const upper_input = try std.ascii.allocUpperString(allocator, input);
    defer allocator.free(upper_input);
    
    for (SQL_KEYWORDS) |keyword| {
        if (std.mem.indexOf(u8, upper_input, keyword) != null) {
            return error.ContainsSQLKeywords;
        }
    }
    
    // Check for HTML/XSS patterns
    if (std.mem.indexOf(u8, input, "<") != null or
        std.mem.indexOf(u8, input, ">") != null or
        std.mem.indexOf(u8, input, "&") != null) {
        return error.ContainsHtmlTags;
    }
    
    // Trim whitespace and return clean copy
    const trimmed = std.mem.trim(u8, input, " \t\n\r");
    return try allocator.dupe(u8, trimmed);
}

pub fn sanitizeDescription(allocator: Allocator, input: []const u8) ![]const u8 {
    return sanitizeString(allocator, input, MAX_DESCRIPTION_LENGTH);
}

pub fn sanitizeCategory(allocator: Allocator, input: []const u8) ![]const u8 {
    return sanitizeString(allocator, input, 50);
}

pub fn sanitizeDate(allocator: Allocator, input: []const u8) ![]const u8 {
    const sanitized = try sanitizeString(allocator, input, 10);
    
    // Additional date format validation (YYYY-MM-DD)
    if (sanitized.len != 10 or
        sanitized[4] != '-' or
        sanitized[7] != '-') {
        allocator.free(sanitized);
        return error.InvalidInput;
    }
    
    // Validate year, month, day are numeric
    for (sanitized, 0..) |char, i| {
        if (i == 4 or i == 7) continue; // Skip dashes
        if (!std.ascii.isDigit(char)) {
            allocator.free(sanitized);
            return error.InvalidInput;
        }
    }
    
    return sanitized;
}

pub fn validateAmount(amount: f64) !void {
    if (amount < 0 or amount > 1_000_000 or !std.math.isFinite(amount)) {
        return error.InvalidInput;
    }
}

// Rate limiting structure
pub const RateLimiter = struct {
    requests: std.HashMap([]const u8, u64, std.hash_map.StringContext, std.hash_map.default_max_load_percentage),
    allocator: Allocator,
    mutex: std.Thread.Mutex,
    window_ms: u64,
    max_requests: u32,
    
    pub fn init(allocator: Allocator, window_ms: u64, max_requests: u32) RateLimiter {
        return .{
            .requests = std.HashMap([]const u8, u64, std.hash_map.StringContext, std.hash_map.default_max_load_percentage).init(allocator),
            .allocator = allocator,
            .mutex = std.Thread.Mutex{},
            .window_ms = window_ms,
            .max_requests = max_requests,
        };
    }
    
    pub fn deinit(self: *RateLimiter) void {
        var iterator = self.requests.iterator();
        while (iterator.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
        }
        self.requests.deinit();
    }
    
    pub fn checkLimit(self: *RateLimiter, client_id: []const u8) !bool {
        self.mutex.lock();
        defer self.mutex.unlock();
        
        const now = std.time.milliTimestamp();
        const key = try self.allocator.dupe(u8, client_id);
        
        if (self.requests.get(key)) |last_request| {
            if (now - last_request < self.window_ms) {
                self.allocator.free(key);
                return false; // Rate limited
            }
        }
        
        try self.requests.put(key, @intCast(now));
        return true;
    }
};