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
- Numbers the plugins using four digits (`0001`, `0002`, ...).
- Creates a single file named:

`Project Plugins.txt`

The output file is created in the root folder being scanned.

### How long does it take?

The scan time depends on the number and size of your REAPER projects.

If you have a large project library containing hundreds or thousands of `.rpp` files, the operation can take **quite some time**.

This is normal: the script has to examine every project file in the selected folder and all of its subdirectories.

A progress window is displayed during the scan so you can see that the operation is still running.

**Do not assume that REAPER has frozen if the scan takes a while.**

The scan can be interrupted at any time using the **STOP** button or the **Esc** key.

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
4. Wait for the scan to complete. Depending on the size of your project library, this may take several minutes or more.
5. Open `Project Plugins.txt`.
6. Install the plugins appearing in the list.

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

The resulting `Project Plugins.txt` contains one plugin name per line, preceded by a four-digit number:

```text
0001 - FabFilter Pro-Q 4
0002 - Kontakt 8
0003 - ReaComp
0004 - ValhallaVintageVerb
