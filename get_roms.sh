#!/bin/sh

mkdir -p roms
curl -s -L -o roms/chipquarium.c8 https://github.com/mattmikolay/chip-8/raw/master/chipquarium/chipquarium.ch8
curl -s -L -o roms/ibm_logo.c8 https://github.com/loktar00/chip8/raw/master/roms/IBM%20Logo.ch8 
curl -s -L -o roms/test_opcode.c8 https://github.com/corax89/chip8-test-rom/raw/master/test_opcode.ch8
curl -s -L -o roms/c8_test.c8 https://github.com/Skosulor/c8int/raw/master/test/c8_test.c8
