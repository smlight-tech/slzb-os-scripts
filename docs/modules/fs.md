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

| Function | Description | Returns |
|----------|-------------|---------|
| `FS.exists(path:string)` | Check if file or folder exists. | `bool` |
| `FS.open(filename:string, mode:string)` | Open a file for reading or writing. See [Berry file documentation](https://berry.readthedocs.io/en/latest/source/en/Chapter-7.html?highlight=open#open-function). | `File` |
| `FS.deleteFile(path:string)` | Delete a file by its full path. Does **not** delete folders. | `bool` |
| `FS.deleteDir(path:string)` | Delete all files in a folder and the folder itself. Does **not** support recursion — subfolders will **not** be deleted. | — |

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
