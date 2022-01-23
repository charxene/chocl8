const std = @import("std");
const sdl = @import("sdl2");
const chocl8 = @import("chocl8.zig");

fn draw(renderer: sdl.Renderer, fbuf: [32]u64) anyerror!void {
    var k: u7 = 0;
    try renderer.setColor(sdl.Color.white);
    while (k < 64) : (k += 1) {
        var j: u7 = 0;
        while (j < fbuf.len) : (j += 1) {
            // std.log.info("{}, {}, {}, {}", .{ j, k, fbuf[j], (fbuf[j] & (@intCast(u32, 1) << @truncate(u5, k))) });
            if ((fbuf[j] & (@intCast(u64, 1) << @truncate(u6, 64 - k))) != 0) {
                try renderer.fillRect(sdl.Rectangle{
                    .x = @intCast(c_int, k) * 10,
                    .y = @intCast(c_int, j) * 10,
                    .width = 10,
                    .height = 10,
                });
            }
        }
    }
}

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
        320,
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
    } else {
        std.log.info("no rom specified", .{});
    }

    var autorun: bool = false;
    mainLoop: while (true) {
        while (sdl.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                .key_up => switch (ev.key_up.keycode) {
                    .s => if (!autorun) chocl8.chip8.step(0),
                    .r => autorun = true,
                    .q => return,
                    else => {},
                },
                else => {},
            }
        }
        if (autorun) {
            chocl8.chip8.step(0);
        }
        try renderer.setColor(sdl.Color.black);
        try renderer.clear();
        try draw(renderer, chocl8.chip8.fbuf);
        renderer.present();
    }
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
