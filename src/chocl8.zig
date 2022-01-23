const std = @import("std");

var prng = std.rand.DefaultPrng.init(0);

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

/// instructions_per_cycle is the number of instructions per a cycle at 60Hz
pub const instructions_per_cycle = 12;

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
    /// sp is the stack pointer
    sp: u8 = 0,
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
    // counter tracks the number of instructions executed
    counter: u64 = 0,

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

    pub fn step(self: *Chip8, keys: u16) void {
        const inst = Instruction.decode(self.mem[self.pc + 1], self.mem[self.pc]);
        self.pc += 2;

        self.counter += 1;
        if (self.counter % instructions_per_cycle == 0) {
            if (self.delay > 0) self.delay -= 1;
            if (self.sound > 0) self.sound -= 1;
        }

        switch (inst.w) {
            0x0 => switch (inst.nn) {
                0xEE => {
                    std.log.info("{}: ret", .{self.pc - 2});
                    self.pc = self.stack[self.sp];
                    self.sp -= 1;
                },
                0xE0 => {
                    std.log.info("{}: clear fbuf", .{self.pc - 2});
                    @memset(@ptrCast([*]u8, self.fbuf[0..]), 0, @sizeOf(u32) * self.fbuf.len);
                },
                else => {
                    @panic("0x0*NN variant uknown");
                },
            },
            0x1 => {
                if (inst.nnn != self.pc - 2) {
                    std.log.info("{}: jump {}", .{ self.pc - 2, inst.nnn });
                }
                self.pc = @as(u16, inst.nnn);
            },
            0x2 => {
                std.log.info("call {}", .{inst.nnn});
                self.sp += 1;
                self.stack[self.sp] = self.pc;
                self.pc = inst.nnn;
            },
            0x3 => {
                std.log.info("{}: jump pc+2 ({}) if r[{}] ({}) == {}", .{ self.pc - 2, self.pc + 2, inst.x, self.reg[inst.x], inst.nn });
                if (self.reg[inst.x] == inst.nn) {
                    self.pc += 2;
                }
            },
            0x4 => {
                std.log.info("{}: jump pc+2 ({}) if r[{}] ({}) != {}", .{ self.pc - 2, self.pc + 2, inst.x, self.reg[inst.x], inst.nn });
                if (self.reg[inst.x] != inst.nn) {
                    self.pc += 2;
                }
            },
            0x5 => {
                std.log.info("{}: jump pc+2 ({}) if r[{}] ({}) == r[{}] ({})", .{ self.pc - 2, self.pc + 2, inst.x, self.reg[inst.x], inst.y, self.reg[inst.y] });
                if (self.reg[inst.x] == self.reg[inst.y]) {
                    self.pc += 2;
                }
            },
            0x6 => {
                std.log.info("{}: r[{}] = {}", .{ self.pc - 2, inst.x, inst.nn });
                self.reg[inst.x] = inst.nn;
            },
            0x7 => {
                std.log.info("{}: r[{}] = r[{}] ({}) + {}", .{ self.pc - 2, inst.x, inst.x, self.reg[inst.x], inst.nn });
                self.reg[inst.x] +%= inst.nn;
            },
            0x8 => switch (inst.n) {
                0x0 => {
                    std.log.info("{}: r[{}] = r[{}] ({})", .{ self.pc - 2, inst.x, inst.y, self.reg[inst.y] });
                    self.reg[inst.x] = self.reg[inst.y];
                },
                0x1 => {
                    std.log.info("{}: r[{}] |= r[{}] ({})", .{ self.pc - 2, inst.x, inst.y, self.reg[inst.y] });
                    self.reg[inst.x] |= self.reg[inst.y];
                },
                0x2 => {
                    std.log.info("{}: r[{}] &= r[{}] ({})", .{ self.pc - 2, inst.x, inst.y, self.reg[inst.y] });
                    self.reg[inst.x] &= self.reg[inst.y];
                },
                0x3 => {
                    std.log.info("{}: r[{}] ^= r[{}] ({})", .{ self.pc - 2, inst.x, inst.y, self.reg[inst.y] });
                    self.reg[inst.x] ^= self.reg[inst.y];
                },
                0x4 => {
                    std.log.info("{}: r[{}] += r[{}] ({})", .{ self.pc - 2, inst.x, inst.y, self.reg[inst.y] });
                    const result = @intCast(u32, self.reg[inst.x]) + @intCast(u32, self.reg[inst.y]);
                    self.reg[0xF] = if (result > 0xFF) 1 else 0;
                    self.reg[inst.x] = @truncate(u8, result);
                },
                0x5 => {
                    std.log.info("{}: r[{}] -= r[{}] ({})", .{ self.pc - 2, inst.x, inst.y, self.reg[inst.y] });
                    self.reg[0xF] = if (self.reg[inst.x] > self.reg[inst.y]) 1 else 0;
                    self.reg[inst.x] -%= self.reg[inst.y];
                },
                0x6 => {
                    std.log.info("{}: r[{}] = r[{}] ({}) >> 1", .{ self.pc - 2, inst.x, inst.x, self.reg[inst.x] });
                    self.reg[0xF] = self.reg[inst.x] & 0x1;
                    self.reg[inst.x] = self.reg[inst.x] >> 1;
                },
                0x7 => {
                    std.log.info("{}: r[{}] = r[{}] ({}) - r[{}] ({})", .{ self.pc - 2, inst.x, inst.y, self.reg[inst.y], inst.x, self.reg[inst.x] });
                    self.reg[0xF] = if (self.reg[inst.y] > self.reg[inst.x]) 1 else 0;
                    self.reg[inst.x] = self.reg[inst.y] -% self.reg[inst.x];
                },
                0xE => {
                    std.log.info("{}: r[{}] = r[{}] ({}) << 1", .{ self.pc - 2, inst.x, inst.x, self.reg[inst.x] });
                    self.reg[0xF] = if (self.reg[inst.x] & 0x80 != 0) 1 else 0;
                    self.reg[inst.x] = self.reg[inst.x] << 1;
                },
                else => {
                    @panic("0x8*NN variant uknown");
                },
            },
            0x9 => {
                std.log.info("{}: jump pc+2 ({}) if r[{}] ({}) != r[{}] ({})", .{ self.pc - 2, self.pc + 2, inst.x, self.reg[inst.x], inst.y, self.reg[inst.y] });
                if (self.reg[inst.x] != self.reg[inst.y]) {
                    self.pc += 2;
                }
            },
            0xA => {
                std.log.info("{}: index={}", .{ self.pc - 2, inst.nnn });
                self.index = inst.nnn;
            },
            0xB => {
                std.log.info("{}: jump r[0] ({}) + {}", .{ self.pc - 2, self.reg[0], inst.nnn });
                self.pc = self.reg[0] + inst.nnn;
            },
            0xC => {
                const rand = prng.random().int(u8);
                std.log.info("{}: r[{}] = rand ({}) & {}", .{ self.pc - 2, inst.x, rand, inst.nn });
                self.reg[inst.x] = inst.nn & rand;
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
            0xE => switch (inst.nn) {
                0x9E => {
                    std.log.info("{}: jump pc+2 ({}) if keys[r[{}] ({})]", .{ self.pc - 2, self.pc + 2, inst.x, self.reg[inst.x] });
                    if (0 != (keys & self.reg[inst.x])) {
                        self.pc += 1;
                    }
                },
                0xA1 => {
                    std.log.info("{}: jump pc+2 ({}) if !keys[r[{}] ({})]", .{ self.pc - 2, self.pc + 2, inst.x, self.reg[inst.x] });
                    if (0 == (keys & self.reg[inst.x])) {
                        self.pc += 1;
                    }
                },
                else => {
                    @panic("0xE*NN variant uknown");
                },
            },
            0xF => switch (inst.nn) {
                0x07 => {
                    std.log.info("{}: reg[{}] = delay ({})", .{ self.pc - 2, inst.x, self.delay });
                    self.reg[inst.x] = self.delay;
                },
                0x0A => {
                    std.log.info("{}: wait k; reg[{}] = k", .{ self.pc - 2, inst.x });
                    if (keys != 0) {
                        var i: u4 = 0;
                        while (i < 16) : (i += 1) {
                            if ((keys & (@intCast(u16, 1) << i)) != 0) {
                                self.reg[inst.x] = i;
                            }
                        }
                    } else {
                        self.pc -= 2; // manually loop till key is pressed
                    }
                },
                0x15 => {
                    std.log.info("{}: delay = r[{}] ({})", .{ self.pc - 2, inst.x, self.reg[inst.x] });
                    self.delay = self.reg[inst.x];
                },
                0x18 => {
                    std.log.info("{}: sound = r[{}] ({})", .{ self.pc - 2, inst.x, self.reg[inst.x] });
                    self.sound = self.reg[inst.x];
                },
                0x1E => {
                    std.log.info("{}: index = index ({}) + r[{}] ({})", .{ self.pc - 2, self.index, inst.x, self.reg[inst.x] });
                    self.index += self.reg[inst.x];
                },
                0x29 => {
                    std.log.info("{}: index = font[reg[{}] ({})]", .{ self.pc - 2, inst.x, self.reg[inst.x] });
                    self.index = 0x50 + self.reg[inst.x] * 5;
                },
                0x33 => {
                    self.mem[self.index] = self.reg[inst.x] / 100;
                    self.mem[self.index + 1] = (self.reg[inst.x] - self.mem[self.index] * 100) / 10;
                    self.mem[self.index + 2] = self.reg[inst.x] - self.mem[self.index] * 100 - self.mem[self.index + 1] * 10;
                    std.log.info("{}: bcd r[{}] ({}): mem[index] = {}, mem[index+1] = {}, mem[index+2] = {}", .{ self.pc - 2, inst.x, self.reg[inst.x], self.mem[self.index], self.mem[self.index + 1], self.mem[self.index + 2] });
                },
                0x55 => {
                    std.log.info("{}: store mem[index ({})] reg[:{}+1]", .{ self.pc - 2, self.index, inst.x });
                    @memcpy(@ptrCast([*]u8, self.mem[self.index..]), @ptrCast([*]u8, self.reg[0..]), 2 * (1 + @intCast(usize, inst.x)));
                },
                0x65 => {
                    std.log.info("{}: load mem[index ({})] reg[:{}+1]", .{ self.pc - 2, self.index, inst.x });
                    @memcpy(@ptrCast([*]u8, self.reg[0..]), @ptrCast([*]u8, self.mem[self.index..]), 2 * (1 + @intCast(usize, inst.x)));
                },
                else => {
                    @panic("0xF*NN variant uknown");
                },
            },
        }
    }
};

// chip8 singleton
pub var chip8 = Chip8.init();
