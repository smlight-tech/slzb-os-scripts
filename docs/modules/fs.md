# FS — File System

> Available since: v3.0.6

Read, check, and delete files and folders on the device.

**Use with caution** — deleting system files can break your device.

## Quick Example

```berry
import FS

if FS.exists("/be/test.be")
  SLZB.log("File exists!")
end
```

## API Reference

| Function | Description |
|----------|-------------|
| `FS.exists(path:string) -> bool` | Check if file or folder exists. |
| `FS.open(filename:string, mode:string="r") -> File` | Open a file and return a [File](#class-file) instance (raises `io_error` on failure). Modes: `"r"` read (file must exist), `"w"` write (truncates), `"a"` append, `"r+"`/`"w+"`/`"a+"` read-write variants; add `"b"` for binary (e.g. `"rb"`). |
| `FS.deleteFile(path:string) -> bool` | Delete a file by its full path. Does **not** delete folders. |
| `FS.deleteDir(path:string) -> nil` | Delete all files in a folder and the folder itself. Does **not** support recursion — subfolders will **not** be deleted. |

### Class File

The object returned by `FS.open()`. Wraps the standard [Berry file class](https://berry.readthedocs.io/en/latest/source/en/Chapter-7.html#file-class). All read methods return `nil` if the file could not be opened; always `close()` files when done.

| Function | Description |
|----------|-------------|
| `File.write(content:string\|bytes) -> nil` | Write a string or a bytes buffer to the file. Requires a write mode. Writes may be buffered — call `flush()` to force them to storage. |
| `File.read(count:int?) -> string` | Read until the end of file, or at most `count` bytes when given. |
| `File.readbytes(count:int?) -> bytes` | Same as `read()` but returns a `bytes` buffer — use for binary files. |
| `File.readline() -> string` | Read one line (up to and including the newline character). Returns `""` at end of file. |
| `File.seek(offset:int) -> nil` | Set the file position to `offset` bytes from the start (clamped to the file bounds). |
| `File.tell() -> int` | Current position, in bytes, from the beginning of the file. |
| `File.size() -> int` | File size in bytes. |
| `File.flush() -> nil` | Flush the write buffer — force all pending writes to storage. |
| `File.close() -> nil` | Close the file and free all associated resources. |

## Examples

### Check if a file exists

```berry
import FS

if FS.exists("/be/test.be")
  SLZB.log("File exists")
else
  SLZB.log("File does not exist")
end
```

### Get file size

```berry
import FS

var file = FS.open("/be/test.be")
if file
  SLZB.log("File size: " .. file.size() .. " bytes")
  file.close()
end
```

### Write and read back a file

```berry
import FS

var f = FS.open("/be/notes.txt", "w")
f.write("hello from Berry\n")
f.close()

f = FS.open("/be/notes.txt")
SLZB.log(f.readline())  # hello from Berry
f.close()
```

### Delete a file

```berry
import FS
FS.deleteFile("/be/test.be")
```

### Delete a directory

```berry
import FS
FS.deleteDir("/be/my_test_directory")
```

## See Also

- [Example: Get file size](../../examples/basic/get_file_size.be)
- [Getting Started: Metadata](../getting-started.md#metadata) — How SLZB-OS loads script files
