import re
import sys
import os

def scan_gta_natives(file_path):
    if not os.path.isfile(file_path):
        print(f"File not found: {file_path}")
        return

    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    native_set = set()

    pattern = r'\b([A-Z_][A-Z0-9_]*)\.([A-Z0-9_]+)\s*\('

    for match in re.findall(pattern, content):
        namespace, func = match
        native_set.add(f"{namespace}.{func}")

    print(f"[+] Found {len(native_set)} namespaced native calls:\n")

    output_file = os.path.splitext(file_path)[0] + "_natives.txt"
    with open(output_file, 'w', encoding='utf-8') as out:
        for native in sorted(native_set):
            print(native)
            out.write(native + '\n')

    print(f"\n[+] Results saved to: {output_file}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scan_natives.py <script.lua>")
        sys.exit(1)

    scan_gta_natives(sys.argv[1])
