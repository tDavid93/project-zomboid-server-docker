#!/usr/bin/env python3
import argparse
import curses
from pathlib import Path

WORKSHOP_ROOT = Path("workshop-mods/content/108600")
LOCAL_ROOT = Path("local-mods")


def parse_kv_file(path):
    data = {}
    for line in path.read_text(errors="ignore").splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            data[k.strip()] = v.strip()
    return data


def find_mod_info_paths():
    paths = []
    if WORKSHOP_ROOT.exists():
        paths.extend(WORKSHOP_ROOT.rglob("mod.info"))
    if LOCAL_ROOT.exists():
        paths.extend(LOCAL_ROOT.rglob("mod.info"))
    return paths


def build_mod_index():
    index = {}
    for mod_info in find_mod_info_paths():
        info = parse_kv_file(mod_info)
        mod_id = info.get("id")
        mod_name = info.get("name") or mod_info.parent.name

        parts = mod_info.parts
        source = "local"
        workshop_id = None
        mod_folder = mod_info.parent.name
        try:
            # workshop-mods/content/108600/<workshopid>/mods/<modfolder>/mod.info
            if "workshop-mods" in parts:
                w_idx = parts.index("108600")
                workshop_id = parts[w_idx + 1]
                source = "workshop"
        except Exception:
            pass

        keys = set()
        if mod_id:
            keys.add(mod_id)
        keys.add(mod_folder)
        if workshop_id:
            keys.add(f"{workshop_id}/{mod_folder}")

        entry = {
            "id": mod_id,
            "name": mod_name,
            "folder": mod_folder,
            "workshop_id": workshop_id,
            "source": source,
            "path": str(mod_info.parent),
        }
        for key in keys:
            index.setdefault(key, []).append(entry)
    return index


def get_ini(path):
    if not path.exists():
        raise FileNotFoundError(path)
    lines = path.read_text(errors="ignore").splitlines()
    return lines


def write_ini(path, lines):
    path.write_text("\n".join(lines) + "\n")


def get_ini_value(lines, key):
    for line in lines:
        if line.startswith(key + "="):
            return line.split("=", 1)[1]
    return ""


def set_ini_value(lines, key, value):
    prefix = key + "="
    new_lines = []
    updated = False
    for line in lines:
        if line.startswith(prefix):
            new_lines.append(prefix + value)
            updated = True
        else:
            new_lines.append(line)
    if not updated:
        new_lines.append(prefix + value)
    return new_lines


def split_mods(raw):
    return [m for m in raw.split(";") if m]


def join_mods(mods):
    return ";".join(mods)


def resolve_mod(mod_key, index):
    entries = index.get(mod_key, [])
    if not entries:
        return None
    # prefer exact id matches first
    for entry in entries:
        if entry.get("id") == mod_key:
            return entry
    return entries[0]


def cmd_list(args, index):
    lines = get_ini(args.config)
    mods = split_mods(get_ini_value(lines, "Mods"))
    for i, mod in enumerate(mods, 1):
        entry = resolve_mod(mod.lstrip("\\"), index)
        if entry:
            name = entry.get("name")
            source = entry.get("source")
            wid = entry.get("workshop_id") or "-"
            print(f"{i:3d}. {mod} -> {name} ({source}, workshop={wid})")
        else:
            print(f"{i:3d}. {mod} -> [unresolved]")


def cmd_resolve(args, index):
    for mod in args.mods:
        entry = resolve_mod(mod.lstrip("\\"), index)
        if entry:
            print(f"{mod}: {entry.get('name')} (id={entry.get('id')}, source={entry.get('source')}, workshop={entry.get('workshop_id')})")
        else:
            print(f"{mod}: [unresolved]")


def cmd_reorder(args, index):
    order = []
    for line in Path(args.order_file).read_text(errors="ignore").splitlines():
        val = line.strip()
        if val and not val.startswith("#"):
            order.append(val)
    lines = get_ini(args.config)
    current = split_mods(get_ini_value(lines, "Mods"))
    current_set = set(current)

    new_mods = []
    for mod in order:
        if mod in current_set:
            new_mods.append(mod)
    for mod in current:
        if mod not in new_mods:
            new_mods.append(mod)

    lines = set_ini_value(lines, "Mods", join_mods(new_mods))
    if args.write:
        write_ini(args.config, lines)
    else:
        print(join_mods(new_mods))


def cmd_enable(args, index):
    lines = get_ini(args.config)
    current = split_mods(get_ini_value(lines, "Mods"))
    current_set = set(current)
    for mod in args.mods:
        if mod not in current_set:
            current.append(mod)
            current_set.add(mod)
    lines = set_ini_value(lines, "Mods", join_mods(current))
    if args.write:
        write_ini(args.config, lines)
    else:
        print(join_mods(current))


def cmd_disable(args, index):
    lines = get_ini(args.config)
    current = split_mods(get_ini_value(lines, "Mods"))
    remove = set(args.mods)
    current = [m for m in current if m not in remove]
    lines = set_ini_value(lines, "Mods", join_mods(current))
    if args.write:
        write_ini(args.config, lines)
    else:
        print(join_mods(current))


def cmd_list_workshop(args, index):
    lines = get_ini(args.config)
    items_raw = get_ini_value(lines, "WorkshopItems")
    items = [i for i in items_raw.split(";") if i]
    for wid in items:
        mod_paths = list(WORKSHOP_ROOT.glob(f"{wid}/mods/*/mod.info"))
        if not mod_paths:
            print(f"{wid}: [not found on disk]")
            continue
        names = []
        for mod_info in mod_paths:
            info = parse_kv_file(mod_info)
            mod_id = info.get("id") or mod_info.parent.name
            mod_name = info.get("name") or mod_info.parent.name
            names.append(f"{mod_name} (id={mod_id})")
        print(f"{wid}: " + "; ".join(names))


def normalize_mod_id(mod_id):
    return mod_id.lstrip("\\")


def build_all_mod_ids(index):
    ids = set()
    for entries in index.values():
        for entry in entries:
            mod_id = entry.get("id") or entry.get("folder")
            if mod_id:
                ids.add(mod_id)
    return sorted(ids)


def get_mod_display(mod_id, index):
    entry = resolve_mod(mod_id, index)
    if not entry:
        return f"{mod_id}  [unresolved]"
    name = entry.get("name")
    source = entry.get("source")
    wid = entry.get("workshop_id") or "-"
    return f"{mod_id}  {name} ({source}, workshop={wid})"


def tui_app(stdscr, args, index):
    curses.curs_set(0)
    stdscr.nodelay(False)
    stdscr.keypad(True)

    lines = get_ini(args.config)
    raw_mods = split_mods(get_ini_value(lines, "Mods"))
    enabled = list(raw_mods)
    enabled_norm = [normalize_mod_id(m) for m in enabled]
    all_mod_ids = build_all_mod_ids(index)

    cursor = 0
    offset = 0
    tab = "enabled"
    dirty = False
    quit_pending = False
    prefix = "\\" if any(m.startswith("\\") for m in enabled) else ""

    while True:
        stdscr.erase()
        height, width = stdscr.getmaxyx()

        header = f"Mod Manager TUI  config={args.config}"
        if dirty:
            header += "  *unsaved*"
        stdscr.addnstr(0, 0, header, width - 1)

        tabs = "[Enabled]" if tab == "enabled" else " Enabled "
        tabs += "  "
        tabs += "[All]" if tab == "all" else " All "
        stdscr.addnstr(1, 0, tabs, width - 1)

        if tab == "enabled":
            items = enabled
            display = [get_mod_display(normalize_mod_id(m), index) for m in items]
        else:
            items = all_mod_ids
            display = []
            enabled_set = set(enabled_norm)
            for mod_id in items:
                mark = "*" if mod_id in enabled_set else " "
                display.append(f"{mark} {get_mod_display(mod_id, index)}")

        list_top = 3
        list_height = max(1, height - list_top - 2)
        if cursor >= len(items):
            cursor = max(0, len(items) - 1)
        if cursor < offset:
            offset = cursor
        if cursor >= offset + list_height:
            offset = cursor - list_height + 1

        for i in range(list_height):
            idx = offset + i
            if idx >= len(items):
                break
            line = display[idx]
            if idx == cursor:
                stdscr.attron(curses.A_REVERSE)
                stdscr.addnstr(list_top + i, 0, line, width - 1)
                stdscr.attroff(curses.A_REVERSE)
            else:
                stdscr.addnstr(list_top + i, 0, line, width - 1)

        help_line = "q quit  s save  tab switch  a add  d disable  p/n move  arrows/jk navigate"
        stdscr.addnstr(height - 1, 0, help_line, width - 1)
        if quit_pending:
            warn = "Unsaved changes. Press q again to quit or s to save."
            stdscr.addnstr(height - 2, 0, warn, width - 1)

        stdscr.refresh()

        ch = stdscr.getch()
        if ch in (curses.KEY_UP, ord("k")):
            cursor = max(0, cursor - 1)
            quit_pending = False
        elif ch in (curses.KEY_DOWN, ord("j")):
            cursor = min(len(items) - 1, cursor + 1)
            quit_pending = False
        elif ch in (curses.KEY_RESIZE,):
            continue
        elif ch in (9,):  # tab
            tab = "all" if tab == "enabled" else "enabled"
            cursor = 0
            offset = 0
            quit_pending = False
        elif ch in (ord("a"),):
            if tab == "all" and items:
                mod_id = items[cursor]
                if mod_id not in enabled_norm:
                    enabled.append(prefix + mod_id)
                    enabled_norm.append(mod_id)
                    dirty = True
            quit_pending = False
        elif ch in (ord("d"),):
            if tab == "enabled" and items:
                mod_raw = items[cursor]
                mod_norm = normalize_mod_id(mod_raw)
                if mod_raw in enabled:
                    idx = enabled.index(mod_raw)
                    enabled.pop(idx)
                    enabled_norm.pop(idx)
                    dirty = True
                    if cursor >= len(enabled):
                        cursor = max(0, len(enabled) - 1)
            quit_pending = False
        elif ch in (ord("p"),):
            if tab == "enabled" and cursor > 0:
                enabled[cursor - 1], enabled[cursor] = enabled[cursor], enabled[cursor - 1]
                enabled_norm[cursor - 1], enabled_norm[cursor] = enabled_norm[cursor], enabled_norm[cursor - 1]
                cursor -= 1
                dirty = True
            quit_pending = False
        elif ch in (ord("n"),):
            if tab == "enabled" and cursor < len(enabled) - 1:
                enabled[cursor + 1], enabled[cursor] = enabled[cursor], enabled[cursor + 1]
                enabled_norm[cursor + 1], enabled_norm[cursor] = enabled_norm[cursor], enabled_norm[cursor + 1]
                cursor += 1
                dirty = True
            quit_pending = False
        elif ch in (ord("s"),):
            lines = set_ini_value(lines, "Mods", join_mods(enabled))
            write_ini(args.config, lines)
            dirty = False
            quit_pending = False
        elif ch in (ord("q"),):
            if dirty and not quit_pending:
                quit_pending = True
            else:
                break
        else:
            quit_pending = False


def cmd_tui(args, index):
    curses.wrapper(tui_app, args, index)


def main():
    parser = argparse.ArgumentParser(description="Manage PZ server Mods list and resolve workshop mod names.")
    parser.add_argument("--config", default="config/Server/servertest.ini", type=Path)

    sub = parser.add_subparsers(dest="cmd", required=True)

    p_list = sub.add_parser("list", help="List enabled mods with resolved names.")
    p_list.set_defaults(func=cmd_list)

    p_resolve = sub.add_parser("resolve", help="Resolve mod names by id.")
    p_resolve.add_argument("mods", nargs="+")
    p_resolve.set_defaults(func=cmd_resolve)

    p_reorder = sub.add_parser("reorder", help="Reorder Mods list based on a file.")
    p_reorder.add_argument("--order-file", required=True)
    p_reorder.add_argument("--write", action="store_true")
    p_reorder.set_defaults(func=cmd_reorder)

    p_enable = sub.add_parser("enable", help="Enable mod ids (append if missing).")
    p_enable.add_argument("mods", nargs="+")
    p_enable.add_argument("--write", action="store_true")
    p_enable.set_defaults(func=cmd_enable)

    p_disable = sub.add_parser("disable", help="Disable mod ids.")
    p_disable.add_argument("mods", nargs="+")
    p_disable.add_argument("--write", action="store_true")
    p_disable.set_defaults(func=cmd_disable)

    p_wk = sub.add_parser("list-workshop", help="Resolve WorkshopItems to mod names.")
    p_wk.set_defaults(func=cmd_list_workshop)

    p_tui = sub.add_parser("tui", help="Launch a terminal UI for managing mods and order.")
    p_tui.set_defaults(func=cmd_tui)

    args = parser.parse_args()
    index = build_mod_index()
    args.func(args, index)


if __name__ == "__main__":
    main()
