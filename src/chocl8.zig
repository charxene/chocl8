const std = @import("std");

const font = [_]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};

const Chip8 = struct {
    /// mem is 4096 bytes of memory
    /// 0x0 to 0x1FF is reserved for internal use
    /// 0x200 is the entry point at which a ROM should be loaded
    mem: [4096]u8 = [_]u8{0} ** 4096,
    /// stack is a stack of size 16 for tracking mem locations
    stack: [16]u16 = [_]u16{0} ** 16,
    /// index is a register for pointing at mem locations
    index: u16 = 0,
    /// delay is a counter decremented at 60hz
    delay: u8 = 0,
    /// sound is a counter decremented at 60hz and produces a tone when sound > 0
    sound: u8 = 0,
    /// reg is a 16 wide bank of 8-bit registers
    reg: [16]u8 = [_]u8{0} ** 16,

    fn init() Chip8 {
        var c8 = Chip8{};
        c8.reset();
        return c8;
    }

    pub fn loadRom(_: Chip8, _: []const u8) void {
        // validate size will fit in memory
        // copy storting at 0x200
    }

    pub fn reset(self: *Chip8) void {
        @memset(@ptrCast([*]u8, self), 0, @sizeOf(Chip8));
        @memcpy(chip8.mem[0x50..], font[0..], font.len);
    }
};

// chip8 singleton
var chip8 = Chip8.init();

pub fn run() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.writeAll(chip8.mem[0..]);
}
