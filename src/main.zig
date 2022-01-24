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
        const file = try std.fs.cwd().openFile(
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
    var keys: u16 = 0;
    mainLoop: while (true) {
        const start = sdl.c.SDL_GetPerformanceCounter();
        while (sdl.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                .key_down => keys |= keymap(ev.key_down.scancode),
                .key_up => switch (ev.key_up.keycode) {
                    .s => if (!autorun) chocl8.chip8.step(keys),
                    .r => autorun = true,
                    .h => return,
                    else => keys &= ~keymap(ev.key_up.scancode),
                },
                else => {},
            }
        }

        if (autorun) {
            var i: usize = 0;
            while (i < chocl8.instructions_per_cycle) : (i += 1) {
                chocl8.chip8.step(keys);
            }
        }

        try renderer.setColor(sdl.Color.black);
        try renderer.clear();
        try draw(renderer, chocl8.chip8.fbuf);
        renderer.present();

        const end = sdl.c.SDL_GetPerformanceCounter();
        const elapsed = 1000.0 * @intToFloat(f64, end - start) / @intToFloat(f64, sdl.c.SDL_GetPerformanceFrequency());
        if (1000.0 / 60.0 >= elapsed) {
            sdl.delay(@floatToInt(u32, 1000.0 / 60.0 - elapsed));
        }
    }
}

fn keymap(keycode: sdl.Scancode) u16 {
    switch (keycode) {
        .@"1" => return 1 << 0x0,
        .@"2" => return 1 << 0x1,
        .@"3" => return 1 << 0x2,
        .@"4" => return 1 << 0xC,
        .q => return 1 << 0x4,
        .w => return 1 << 0x5,
        .e => return 1 << 0x6,
        .r => return 1 << 0xD,
        .a => return 1 << 0x7,
        .s => return 1 << 0x8,
        .d => return 1 << 0x9,
        .f => return 1 << 0xE,
        .z => return 1 << 0xA,
        .x => return 1 << 0x0,
        .c => return 1 << 0xB,
        .v => return 1 << 0xF,
        else => return 0,
    }
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
