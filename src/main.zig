const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");

// Windows-first cross-platform shell
const is_windows = builtin.os.tag == .windows;

const Shell = struct {
    allocator: Allocator,
    running: bool,

    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return Self{
            .allocator = allocator,
            .running = true,
        };
    }

    pub fn run(self: *Self) !void {
        const shell_name = if (is_windows) "zhell (Windows)" else "zhell";
        print("{s} - Cross-Platform Shell\n", .{shell_name});
        print("Type 'help' for commands, 'exit' to quit\n\n");

        var input_buffer: [1024]u8 = undefined;

        while (self.running) {
            print("zhell> ");

            if (try std.io.getStdIn().reader().readUntilDelimiterOrEof(input_buffer[0..], '\n')) |input| {
                const trimmed = std.mem.trim(u8, input, " \t\r\n");
                if (trimmed.len > 0) {
                    try self.executeCommand(trimmed);
                }
            }
        }
    }

    fn executeCommand(self: *Self, command: []const u8) !void {
        // Parse command and arguments
        var parts = std.mem.split(u8, command, " ");
        const cmd = parts.next() orelse return;

        // Handle built-in commands
        if (std.mem.eql(u8, cmd, "exit")) {
            self.running = false;
            print("Goodbye!\n");
            return;
        }

        if (std.mem.eql(u8, cmd, "help")) {
            try self.showHelp();
            return;
        }

        if (std.mem.eql(u8, cmd, "pwd")) {
            try self.printWorkingDirectory();
            return;
        }

        if (std.mem.eql(u8, cmd, "cd")) {
            const path = parts.next() orelse {
                print("cd: missing directory argument\n");
                return;
            };
            try self.changeDirectory(path);
            return;
        }

        if (std.mem.eql(u8, cmd, "ls") or std.mem.eql(u8, cmd, "dir")) {
            const path = parts.next() orelse ".";
            try self.listDirectory(path);
            return;
        }

        // Execute external command
        try self.executeExternalCommand(command);
    }

    fn showHelp(self: *Self) !void {
        _ = self;
        print("zhell built-in commands:\n");
        print("  help  - Show this help message\n");
        print("  exit  - Exit the shell\n");
        print("  pwd   - Print working directory\n");
        print("  cd    - Change directory\n");
        print("  ls    - List directory contents (also 'dir')\n");
        print("\nOther commands will be executed as external programs.\n");
    }

    fn printWorkingDirectory(self: *Self) !void {
        var buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
        const cwd = try std.process.getCwd(buf[0..]);
        print("{s}\n", .{cwd});
        _ = self;
    }

    fn changeDirectory(self: *Self, path: []const u8) !void {
        std.process.changeCurDir(path) catch |err| {
            switch (err) {
                error.FileNotFound => print("cd: directory not found: {s}\n", .{path}),
                error.NotDir => print("cd: not a directory: {s}\n", .{path}),
                error.AccessDenied => print("cd: access denied: {s}\n", .{path}),
                else => print("cd: error changing to directory: {s}\n", .{path}),
            }
        };
        _ = self;
    }

    fn listDirectory(self: *Self, path: []const u8) !void {
        var dir = std.fs.cwd().openDir(path, .{ .iterate = true }) catch |err| {
            switch (err) {
                error.FileNotFound => print("ls: directory not found: {s}\n", .{path}),
                error.NotDir => print("ls: not a directory: {s}\n", .{path}),
                error.AccessDenied => print("ls: access denied: {s}\n", .{path}),
                else => print("ls: error opening directory: {s}\n", .{path}),
            }
            return;
        };
        defer dir.close();

        var iterator = dir.iterate();
        while (try iterator.next()) |entry| {
            const entry_type = switch (entry.kind) {
                .directory => if (is_windows) "<DIR>" else "d",
                .file => if (is_windows) "     " else "f",
                .sym_link => if (is_windows) "<LNK>" else "l",
                else => if (is_windows) "<?>" else "?",
            };
            
            if (is_windows) {
                // Windows-style listing
                print("{s}  {s}\n", .{ entry_type, entry.name });
            } else {
                // Unix-style listing  
                print("{s} {s}\n", .{ entry_type, entry.name });
            }
        }
        _ = self;
    }

    fn executeExternalCommand(self: *Self, command: []const u8) !void {
        var parts = std.mem.split(u8, command, " ");
        const cmd = parts.next() orelse return;

        // Collect arguments
        var args = ArrayList([]const u8).init(self.allocator);
        defer args.deinit();

        // On Windows, try adding .exe extension if command doesn't have one
        var cmd_with_ext: [std.fs.MAX_PATH_BYTES]u8 = undefined;
        const final_cmd = if (is_windows and !std.mem.endsWith(u8, cmd, ".exe") and !std.mem.endsWith(u8, cmd, ".com") and !std.mem.endsWith(u8, cmd, ".bat")) blk: {
            const len = @min(cmd.len, std.fs.MAX_PATH_BYTES - 4);
            @memcpy(cmd_with_ext[0..len], cmd[0..len]);
            @memcpy(cmd_with_ext[len..len+4], ".exe");
            break :blk cmd_with_ext[0..len+4];
        } else cmd;

        try args.append(final_cmd);
        while (parts.next()) |arg| {
            try args.append(arg);
        }

        // Execute the command
        var child_process = std.process.Child.init(args.items, self.allocator);
        child_process.stdout_behavior = .Inherit;
        child_process.stderr_behavior = .Inherit;
        child_process.stdin_behavior = .Inherit;

        const result = child_process.spawnAndWait() catch |err| {
            switch (err) {
                error.FileNotFound => {
                    // On Windows, if .exe version failed, try original command
                    if (is_windows and !std.mem.eql(u8, cmd, final_cmd)) {
                        args.items[0] = cmd;
                        var retry_process = std.process.Child.init(args.items, self.allocator);
                        retry_process.stdout_behavior = .Inherit;
                        retry_process.stderr_behavior = .Inherit;
                        retry_process.stdin_behavior = .Inherit;
                        
                        _ = retry_process.spawnAndWait() catch {
                            print("zhell: command not found: {s}\n", .{cmd});
                            return;
                        };
                        return;
                    }
                    print("zhell: command not found: {s}\n", .{cmd});
                    return;
                },
                else => {
                    print("zhell: error executing command: {s}\n", .{cmd});
                    return;
                },
            }
        };

        switch (result) {
            .Exited => |code| {
                if (code != 0) {
                    // Command exited with non-zero status, but don't print error
                    // as the command itself should have printed any error messages
                }
            },
            .Signal => |signal| {
                print("zhell: command terminated by signal {d}\n", .{signal});
            },
            .Stopped => |signal| {
                print("zhell: command stopped by signal {d}\n", .{signal});
            },
            .Unknown => |status| {
                print("zhell: command exited with unknown status {d}\n", .{status});
            },
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var shell = Shell.init(allocator);
    try shell.run();
}

test "shell initialization" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var shell = Shell.init(allocator);
    try std.testing.expect(shell.running == true);
}

test "platform detection" {
    // Test that platform detection compiles and works
    const platform_name = if (is_windows) "Windows" else "Unix";
    try std.testing.expect(platform_name.len > 0);
}