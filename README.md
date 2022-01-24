# chocl8

A CHIP-8 emulator written in Zig

![chocl8chip8](https://github.com/charxene/chocl8/blob/main/screenshot.png?raw=true)

## Getting started 

```
zig build
```

Download some ROM files: 

```
./get_roms.sh
```

And play! Press `r` to run the game or `s` to step. 
```
./zig-out/bin/chocl8 roms/chipquarium.c8
```

## Controls

The 16 keys physical keys bounded by 1234 at the top and zxcv 
at the bottom represent the hex num pad. Additionally, these keys 
are also defined: 

* `h` quit chocl8
* `s` step a single cycle
* `r` run chocl8

## Resources

* [Guide to making a CHIP-8 emulator](https://tobiasvl.github.io/blog/write-a-chip-8-emulator/)
* [Cowgod's CHIP-8 Technical Reference v1.0](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM)
* [Skosulor's c8int test rom](https://github.com/Skosulor/c8int)
* [corax89's chip8 test rom](https://github.com/corax89/chip8-test-rom)
* [Awesome CHIP-8](https://chip-8.github.io/links/)

## TODO 

- [ ] audio
- [ ] support non posix CLI
- [ ] wasm build + web interface

