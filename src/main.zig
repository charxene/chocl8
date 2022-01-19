const std = @import("std");
const sdl = @import("sdl2");
const chocl8 = @import("chocl8.zig");

pub fn main() anyerror!void {
    try sdl.init(.{
        .video = true,
        .events = true,
        .audio = true,
    });
    defer sdl.quit();

    const window = try sdl.createWindow(
        "chocl8",
        .{ .centered = {} },
        .{ .centered = {} },
        640,
        480,
        .{ .shown = true },
    );
    defer window.destroy();

    const renderer = try sdl.createRenderer(window, null, .{ .accelerated = true });
    defer renderer.destroy();

    if (std.os.argv.len > 1) {
        std.log.info("loading rom from {s}", .{std.os.argv[1]});
        const file = try std.fs.openFileAbsolute(
            std.mem.span(std.os.argv[1]),
            .{ .read = true },
        );
        defer file.close();
        var data: [4096]u8 = undefined;
        const n = try file.readAll(&data);
        chocl8.chip8.loadRom(data[0..n]);
        try chocl8.run();
    } else {
        std.log.info("no rom specified", .{});
    }

    // mainLoop: while (true) {
    //     while (sdl.pollEvent()) |ev| {
    //         switch (ev) {
    //             .quit => break :mainLoop,
    //             else => {},
    //         }
    //     }

    //     try renderer.setColorRGB(0xF7, 0xA4, 0x1D);
    //     try renderer.clear();

    //     renderer.present();
    // }
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
