import re
import sys
import os
from collections import defaultdict

def extract_used_natives(lua_code):
    pattern = r'\b([A-Z_][A-Z0-9_]*)\.([A-Z_][A-Z0-9_]+)\s*\('
    matches = re.findall(pattern, lua_code)
    return set(matches) 

def extract_native_definitions(native_file_path):
    with open(native_file_path, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()

    native_map = {}
    for line in lines:
        match = re.match(r'^\s*([A-Z0-9_]+)\s*=\s*function\(.*\)\s*return .*?end', line)
        if match:
            func_name = match.group(1)
            clean_line = line.split(";")[0].strip()  
            native_map[func_name] = clean_line
    return native_map

def inject_grouped_natives(source_path, natives_path, output_path):
    with open(source_path, 'r', encoding='utf-8') as f:
        source_code = f.read()

    used_natives = extract_used_natives(source_code)
    native_defs = extract_native_definitions(natives_path)

    grouped = defaultdict(list)
    missing = []

    for ns, func in used_natives:
        if func in native_defs:
            grouped[ns].append(native_defs[func])
        else:
            missing.append(f"{ns}.{func}")

    with open(output_path, 'w', encoding='utf-8') as out:
        out.write("-- Injected Native Tables\n\n")
        for ns in sorted(grouped.keys()):
            out.write(f"{ns} = {{\n")
            for def_line in grouped[ns]:
                out.write(f"    {def_line},\n")
            out.write("}\n\n")

        out.write("-- Original Script:\n\n")
        out.write(source_code)

    print(f"[+] Injected {sum(len(v) for v in grouped.values())} native definitions into {len(grouped)} namespaces.")
    if missing:
        print(f"[!] {len(missing)} natives missing from definitions:")
        for m in missing:
            print("    " + m)
    print(f"[+] Output saved to: {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python inject_natives.py <source.lua> <natives.lua>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = os.path.splitext(input_file)[0] + "-injected.lua"
    inject_grouped_natives(input_file, sys.argv[2], output_file)

