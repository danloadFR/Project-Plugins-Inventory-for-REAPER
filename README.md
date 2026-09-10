# Project Plugins Inventory for REAPER

**Find out which plugins your REAPER projects actually use.**

`Project Plugins Inventory` is a Lua ReaScript for [REAPER](https://www.reaper.fm/) that recursively scans your REAPER project folder and creates a numbered list of all plugins referenced by your `.rpp` projects.

It is particularly useful when **moving to a new computer, reinstalling an operating system, or rebuilding a REAPER installation**.

Instead of reinstalling your entire plugin collection, you can first find out which plugins are actually required by your existing projects.

## Why?

Over the years, it is easy to accumulate hundreds of plugins, many of which may no longer be used by any project.

When you have to:

- replace a computer,
- recover from a system failure,
- reinstall Windows, macOS or Linux,
- move your REAPER setup to another machine,

you may not want to reinstall everything.

This script gives you a simple answer to:

> **"Which plugins do my existing REAPER projects actually depend on?"**

## What it does

The script:

- Recursively scans the **default REAPER project folder** configured in `Preferences > Paths`.
- Searches all subdirectories.
- Reads `.rpp` files directly as text.
- Does **not** open or load the projects in REAPER.
- Extracts plugin references from the project files.
- Removes duplicate plugin names.
- Removes plugin format prefixes such as `VST3:`, `VSTi:` and `CLAP:`.
- Sorts the plugin names alphabetically.
- Numbers the plugins from `001` to `999`.
- Creates a single file named:

`Project Plugins.txt`

The output file is created in the root folder being scanned.

## Supported plugin formats

The script currently looks for plugin entries used by REAPER for:

- VST / VSTi
- VST2 / VST3
- CLAP
- JSFX
- Audio Units (AU)
- DirectX (DX)

The plugin format itself is not included in the output because, for the intended use of this script, the plugin name is what matters.

## Missing or offline plugins

The script does not try to determine whether a plugin is currently installed.

This is intentional.

If a project references a plugin that is:

- missing,
- offline,
- unavailable,
- replaced,

the reference can still appear in the inventory.

This makes the resulting list useful when rebuilding a system from scratch.

## Example use case

Imagine you have 500 REAPER projects and several hundred plugins installed on your old computer.

Your computer dies and you need to rebuild your system.

Instead of trying to remember which plugins were used over the years:

1. Make your REAPER project folder available on the new system.
2. Run `Project Plugins Inventory`.
3. The script scans all `.rpp` files.
4. Open `Project Plugins.txt`.
5. Install the plugins appearing in the list.

You now have a much more focused list of plugins to reinstall.

## Installation

Copy:

`Project_Plugins_Inventory.lua`

to your REAPER Scripts folder.

In REAPER:

**Actions → Show action list → ReaScript → Load...**

Select `Project_Plugins_Inventory.lua`.

You can then run it like any other ReaScript.

## Progress window

The script displays a progress window while scanning.

It shows:

- number of projects scanned;
- number of unique plugins found.

The scan can be interrupted at any time using the **STOP** button or the **Esc** key.

If the scan is interrupted, the existing `Project Plugins.txt` file is **not modified**.

## Output

The resulting `Project Plugins.txt` contains one plugin name per line, preceded by a three-digit number:

```text
001 - FabFilter Pro-Q 4
002 - Kontakt 8
003 - ReaComp
004 - ValhallaVintageVerb
```

The list is sorted alphabetically and each plugin appears only once.

The numbering runs from `001` to `999`.

## Requirements

- REAPER 7.x
- Lua ReaScript support

The script is written in Lua and is intended to be **cross-platform**.

It does not rely on Windows-specific APIs.

It should therefore work on:

- Windows
- macOS
- Linux

although platform-specific testing is welcome.

## Contributing / Testing

Feedback, bug reports and testing on different REAPER versions and operating systems are welcome.

In particular, testing on **macOS and Linux** would be useful to confirm full cross-platform compatibility.

## License

MIT License

---

**Project Plugins Inventory**  
A small utility for a very practical problem: **know what you actually need before rebuilding your REAPER system.**
