pub const ServerConfig = struct {
    pub const port: u16 = 3000;
    pub const max_clients: u32 = 100000;
    pub const max_body_size: usize = 10 * 1024 * 1024; // 10MB
    pub const threads: u32 = 2;
    pub const workers: u32 = 1;
    pub const public_folder: []const u8 = "public";
};
