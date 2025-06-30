const std = @import("std");
const zap = @import("zap");

const ExpenseService = @import("services/expense_service.zig").ExpenseService;
const SummaryService = @import("services/summary_service.zig").SummaryService;
const zqlite = @import("zqlite");
const ServerConfig = @import("config.zig").ServerConfig;
const database = @import("database/sqlite.zig");

const ExpenseEndpoint = @import("endpoints/expense_endpoint.zig").ExpenseEndpoint;
const SummaryEndpoint = @import("endpoints/summary_endpoint.zig").SummaryEndpoint;
const HealthEndpoint = @import("endpoints/health_endpoint.zig").HealthEndpoint;
const validation = @import("utils/validation.zig");

fn on_request(request: zap.Request) !void {
    if (request.path) |the_path| {
        std.debug.print("Unmatched request path: {s}\n", .{the_path});
    }

    try request.sendJson(
        \\{
        \\  "message": "Expenses Service API",
        \\  "endpoints": {
        \\    "GET /api/expenses": "List all expenses",
        \\    "POST /api/expenses": "Add new expense",
        \\    "GET /api/expenses/{id}": "Get specific expense",
        \\    "DELETE /api/expenses/{id}": "Delete expense",
        \\    "GET /api/summary": "Get expenses summary",
        \\    "GET /healthz": "Health check",
        \\  }
        \\}
    );
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    defer {
        const has_leaked = gpa.detectLeaks();
        std.debug.print("Memory leaks detected: {}\n", .{has_leaked});
    }

    const allocator = gpa.allocator();

    // Initialize database with zqlite.Pool
    var db_pool = try zqlite.Pool.init(allocator, .{
        .size = 10,
        .path = "expenses.db",
        .on_first_connection = &database.initializeDatabase,
        .on_connection = &database.configureConnection,
    });
    defer db_pool.deinit();

    // Initialize validation
    try validation.initValidators(allocator);
    defer validation.deinitValidators(allocator);

    // Initialize services with zqlite pool
    var expense_service = ExpenseService.initWithPool(db_pool, allocator);
    var summary_service = SummaryService.initWithPool(db_pool, allocator);

    // Setup listener
    var listener = zap.Endpoint.Listener.init(
        allocator,
        .{
            .port = ServerConfig.port,
            .on_request = on_request,
            .log = true,
            .max_clients = ServerConfig.max_clients,
            .max_body_size = ServerConfig.max_body_size,
            .public_folder = ServerConfig.public_folder,
        },
    );
    defer listener.deinit();

    // Create and register endpoints
    var expense_endpoint = ExpenseEndpoint.init("/api/expenses", &expense_service);
    var summary_endpoint = SummaryEndpoint.init("/api/summary", &summary_service);
    var health_endpoint = HealthEndpoint.init("/healthz");

    try listener.register(&expense_endpoint);
    try listener.register(&summary_endpoint);
    try listener.register(&health_endpoint);

    try listener.listen();

    std.debug.print("🚀 Server running on http://localhost:{} with SQLite!\n", .{ServerConfig.port});

    zap.start(.{
        .threads = ServerConfig.threads,
        .workers = ServerConfig.workers,
    });
}
