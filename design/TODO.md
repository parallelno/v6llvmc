Investigate if it is possible to teach compiler+linker to operate fraction of address.
like take a hi or lo byte of a address that will be resolved at the linking time.
============================
A special aligment that guarantee aligment INTO block, not at start of the block.
For example the data below all:
static block_align(256) uint8_t arr[10]
static block_align(256) uint8_t arr[10]
static int A = 10;
Research it. perhaps it can be done via lld scripts.
================================
possible bug. the svofski line draw program doesnt work when compiled with v6asm.
compare v6asm binary output with what the downloaded line bin from https://svofski.github.io/pretty-8080-assembler/
================================
optimization template:
make an optimization peephole design document and store it to design\future_plans\ folder. add it to design\future_plans\README.md.
...
=================================
this compiles wrongly when draw_pixel is not inlined.
    // Draw a sin wave across the screen.
    for (int x = 0; x < 256; x++) {
        uint8_t y = 127 + sin8(x);
        draw_pixel(x, y);
    }