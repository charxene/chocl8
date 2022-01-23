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

const Instruction = struct {
    short: u16,
    w: u4,
    x: u4,
    y: u4,
    n: u4,
    nn: u8,
    nnn: u12,

    fn decode(lo: u8, hi: u8) Instruction {
        return Instruction{
            .short = @as(u16, hi) << 8 | @as(u16, lo),
            .w = @truncate(u4, hi >> 4),
            .x = @truncate(u4, hi),
            .y = @truncate(u4, lo >> 4),
            .n = @truncate(u4, lo),
            .nn = lo,
            .nnn = @as(u12, hi & 0xF) << 8 | @as(u12, lo),
        };
    }
};

const Chip8 = struct {
    /// mem is 4096 bytes of memory
    /// 0x0 to 0x1FF is reserved for internal use
    /// 0x200 is the entry point at which a ROM should be loaded
    mem: [4096]u8 = [_]u8{0} ** 4096,
    /// stack is a stack of size 16 for tracking mem locations
    stack: [16]u16 = [_]u16{0} ** 16,
    // pc is the program counter
    pc: u16 = 0,
    /// index is a register for pointing at mem locations
    index: u16 = 0,
    /// delay is a counter decremented at 60hz
    delay: u8 = 0,
    /// sound is a counter decremented at 60hz and produces a tone when sound > 0
    sound: u8 = 0,
    /// reg is a 16 wide bank of 8-bit registers
    reg: [16]u8 = [_]u8{0} ** 16,
    // fbuf is the framebuffer of the screen
    fbuf: [32]u64 = [_]u64{0} ** 32,

    fn init() Chip8 {
        var c8 = Chip8{};
        //@memset(@ptrCast([*]u8, &c8), 0, @sizeOf(Chip8));
        @memcpy(c8.mem[0x50..], font[0..], font.len);
        return c8;
    }

    pub fn loadRom(self: *Chip8, data: []const u8) void {
        // validate size will fit in memory
        if (self.mem.len - 0x200 < data.len) {
            // return error
        }
        @memcpy(self.mem[0x200..], @ptrCast([*]const u8, data[0..]), data.len);
        self.pc = 0x200;
    }

    pub fn step(self: *Chip8) void {
        const inst = Instruction.decode(self.mem[self.pc + 1], self.mem[self.pc]);
        //std.log.info("inst {} {} {} {}", .{ inst.w, inst.x, inst.y, inst.n });
        self.pc += 2;
        switch (inst.w) {
            0x0 => {
                // clear screen
                std.log.info("{}: clear", .{self.pc - 2});
                @memset(@ptrCast([*]u8, self.fbuf[0..]), 0, @sizeOf(u32) * self.fbuf.len);
            },
            0x1 => {
                // jump to nnn
                // std.log.info("{}: j {}", .{ self.pc - 2, inst.nnn });
                if (inst.nnn == self.pc - 2) {
                    //@panic("infinite loop");
                }
                self.pc = @as(u16, inst.nnn);
            },
            0x6 => {
                std.log.info("{}: r[{}] = {}", .{ self.pc - 2, inst.x, inst.nn });
                self.reg[inst.x] = inst.nn;
            },
            0x7 => {
                std.log.info("{}: r[{}] = r[{}] ({}) + {}", .{ self.pc - 2, inst.x, inst.x, self.reg[inst.x], inst.nn });
                self.reg[inst.x] += inst.nn;
            },
            0xA => {
                std.log.info("{}: i={}", .{ self.pc - 2, inst.nnn });
                self.index = inst.nnn;
            },
            0xD => {
                // draw sprite
                std.log.info("{}: drawing mem[{}] with h={}px @(r[{}]{}, r[{}]{})", .{ self.pc - 2, self.index, inst.n, inst.x, self.reg[inst.x], inst.y, self.reg[inst.y] });
                const height: u8 = inst.n;
                const x: u8 = @truncate(u6, self.reg[@truncate(u4, inst.x)] % 64);
                const y: u8 = self.reg[@truncate(u4, inst.y)] % 32;
                var i: usize = 0;
                while ((i < height) and (y + i < 32)) : (i += 1) {
                    self.fbuf[y + i] ^= @intCast(u64, self.mem[self.index + i]) << @truncate(u6, 8 * 7 - x);
                }
            },
            else => {
                std.log.info("unimplemented", .{});
            },
        }
    }
};

// chip8 singleton
pub var chip8 = Chip8.init();
