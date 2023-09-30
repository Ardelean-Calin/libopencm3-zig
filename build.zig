const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = std.zig.CrossTarget{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
    };

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall });

    const lib = b.addStaticLibrary(.{
        .name = "opencm3",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .target = target,
        .optimize = .ReleaseSmall,
    });

    lib.defineCMacroRaw("STM32L0");

    // const build_path = b.build_root.path.?;
    const source_files = [_][]const u8{
        "lib/stm32/common/adc_common_v2.c",
        "lib/stm32/common/crc_common_all.c",
        "lib/stm32/common/crc_v2.c",
        "lib/stm32/common/crs_common_all.c",
        "lib/stm32/common/desig_common_all.c",
        "lib/stm32/common/desig_common_v1.c",
        "lib/stm32/common/dma_common_l1f013.c",
        "lib/stm32/common/dma_common_csel.c",
        "lib/stm32/common/exti_common_all.c",
        "lib/stm32/common/flash_common_all.c",
        "lib/stm32/common/flash_common_l01.c",
        "lib/stm32/common/gpio_common_all.c",
        "lib/stm32/common/gpio_common_f0234.c",
        "lib/stm32/common/i2c_common_v2.c",
        "lib/stm32/common/iwdg_common_all.c",
        "lib/stm32/common/lptimer_common_all.c",
        "lib/stm32/common/pwr_common_v1.c",
        "lib/stm32/common/pwr_common_v2.c",
        "lib/stm32/common/rcc_common_all.c",
        "lib/stm32/common/rng_common_v1.c",
        "lib/stm32/common/rtc_common_l1f024.c",
        "lib/stm32/common/spi_common_all.c",
        "lib/stm32/common/spi_common_v1.c",
        "lib/stm32/common/spi_common_v1_frf.c",
        "lib/stm32/common/timer_common_all.c",
        "lib/stm32/common/usart_common_all.c",
        "lib/stm32/common/usart_common_v2.c",
        "lib/stm32/l0/iwdg.c",
        "lib/stm32/l0/rng.c",
        "lib/stm32/l0/rcc.c",
        "lib/stm32/l0/i2c.c",
        "lib/cm3/systick.c",
    };
    lib.addCSourceFiles(&source_files, &[_][]const u8{"-std=c99"});
    lib.addIncludePath(.{ .path = "include" });

    // This makes the ./include/libopencm3 directory available to anyone using the library.
    // The folder will be available at the path "libopencm3" so you can do @cImport("libopencm3/stm32/gpio.h");
    // for example.

    // This doesn't work for some reason.
    lib.installHeadersDirectory("include/libopencm3", "libopencm3");

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_main_tests = b.addRunArtifact(main_tests);

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build test`
    // This will evaluate the `test` step rather than the default, which is "install".
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
