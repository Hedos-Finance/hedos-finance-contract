import os
import struct
import sys

def read_u32(f):
    return struct.unpack("<I", f.read(4))[0]

def main():
    # Đường dẫn mặc định (tùy chỉnh nếu cần)
    default_path = "hedos-hedging-vault/build/hedos-hedging-vault/package-metadata.bcs"

    # Nếu truyền từ CLI thì dùng path đó, không thì dùng mặc định
    path = sys.argv[1] if len(sys.argv) > 1 else default_path

    if not os.path.exists(path):
        print(f"❌ File không tồn tại: {path}")
        return

    with open(path, "rb") as f:
        magic = f.read(4)
        if magic != b'A1ME':
            print("❌ Đây không phải file package metadata hợp lệ (không đúng magic header)")
            return

        _major = read_u32(f)
        _minor = read_u32(f)

        name_len = read_u32(f)
        f.read(name_len)  # skip package name

        addr_len = read_u32(f)
        f.read(addr_len)  # skip address

        module_count = read_u32(f)

        deps = set()

        for _ in range(module_count):
            module_len = read_u32(f)
            f.read(module_len)  # skip bytecode

            handle_count = read_u32(f)
            for _ in range(handle_count):
                addr_len = read_u32(f)
                addr = f.read(addr_len)
                name_len = read_u32(f)
                name = f.read(name_len)
                deps.add((addr.hex(), name.decode()))

        print(f"\n✅ Tổng số dependencies (module handles): {len(deps)}\n")
        for addr, name in sorted(deps):
            print(f"• {addr}::{name}")

if __name__ == "__main__":
    main()
