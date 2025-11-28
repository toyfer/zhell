# zhell Usage Examples

This document shows how to use zhell once it's built and running.

## Starting zhell

```bash
# Build the project
zig build

# Run zhell
./zig-out/bin/zhell
```

## Built-in Commands

### Getting Help
```
zhell> help
zhell built-in commands:
  help  - Show this help message
  exit  - Exit the shell
  pwd   - Print working directory
  cd    - Change directory
  ls    - List directory contents (also 'dir')

Other commands will be executed as external programs.
```

### Navigation Commands
```
zhell> pwd
/home/user/projects/zhell

zhell> ls
d .git
d src
f README.md
f TODO.md
f build.zig

zhell> cd src
zhell> pwd
/home/user/projects/zhell/src

zhell> ls
f main.zig

zhell> cd ..
```

### Using External Commands
```
zhell> echo "Hello from zhell!"
Hello from zhell!

zhell> cat README.md
# zhell - Cross-Platform Shell
...

# On Windows
zhell> dir
<DIR>  .git
<DIR>  src
       README.md
       TODO.md
       build.zig
```

## Platform Differences

### Windows
- Displays "zhell (Windows)" on startup
- Uses Windows-style directory listing (`<DIR>` for directories)
- Automatically tries `.exe` extension for commands

### Linux/Unix/macOS
- Displays "zhell" on startup
- Uses Unix-style directory listing (`d` for directories, `f` for files)
- Direct command execution

## Exit
```
zhell> exit
Goodbye!
```