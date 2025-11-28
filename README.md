# zhell - Cross-Platform Shell

A cross-platform shell written in Zig, with Windows as the primary target and other platforms as secondary targets.

## Features

- Cross-platform compatibility (Windows, Linux, macOS)
- Built-in commands (cd, pwd, help, exit)
- External command execution
- Simple and clean command-line interface
- Windows-optimized with fallback support for other platforms

## Building

Make sure you have [Zig](https://ziglang.org/) installed (version 0.13.0 or later).

```bash
# Build the project
zig build

# Run the shell
zig build run

# Run tests
zig build test
```

## Usage

Once built, you can run zhell:

```bash
./zig-out/bin/zhell
```

### Built-in Commands

- `help` - Show available commands
- `exit` - Exit the shell
- `pwd` - Print working directory
- `cd <directory>` - Change directory

### External Commands

Any command not recognized as a built-in will be executed as an external program.

## Development

See [TODO.md](TODO.md) for the current development roadmap and tasks.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.