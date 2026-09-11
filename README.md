# Project Plugins Inventory for REAPER

A Lua ReaScript for [REAPER](https://www.reaper.fm/) that scans your REAPER project files and creates a unique list of all plugins used across your projects.

## Why?

When moving to a new computer, reinstalling Windows, recovering from a system crash, or rebuilding a REAPER installation, it can be surprisingly difficult to know which plugins you actually need to reinstall.

Your REAPER projects may contain references to hundreds of plugins, including plugins you have not used for years.

**Project Plugins Inventory** scans your existing REAPER projects and creates a simple list of the plugins they actually use.

This makes it much easier to rebuild a REAPER installation without having to remember every plugin you have ever installed.

## Features

* Recursively scans the REAPER project folder and all its subfolders.
* Reads `.rpp` project files directly without opening them in REAPER.
* Detects plugin references in project files.
* Creates a unique list of plugins found across all projects.
* Sorts the list alphabetically.
* Removes plugin format prefixes such as `VST3:`, `VSTi:`, `CLAP:`, etc.
* Keeps references to missing, offline, or replaced plugins.
* Supports:

  * VST
  * VSTi
  * VST3
  * VST3i
  * CLAP
  * JSFX
  * AU
  * DX
* Displays a progress window while scanning.
* Provides a **STOP** button and `Esc` key cancellation.
* The existing output file is not modified if the scan is cancelled.
* Uses a batched scanning process to keep the scan extremely fast while allowing REAPER to remain responsive.
* Works with large project collections.

## Output

The script creates:

`Project Plugins.txt`

in the root of the REAPER project folder being scanned.

The output is a simple numbered list, for example:

```text
0001 - AmpliTube 5
0002 - FabFilter Pro-Q 4
0003 - Kontakt 8
0004 - PSP Chamber
0005 - TDR VOS SlickEQ
```

Four digits are used for numbering by default. If more than 9999 plugins are found, the numbering automatically expands to five digits and beyond.

## Installation

Copy:

`Project_Plugins_Inventory.lua`

to your REAPER Scripts folder.

In REAPER:

1. Open **Actions → Show action list**.
2. Click **Load/ReaScript**.
3. Select `Project_Plugins_Inventory.lua`.
4. Run the script.

The script uses the project folder defined by REAPER in:

**Preferences → General → Paths → Default path to save new projects**

No project needs to be opened before running the script.

## How it works

The script recursively walks through the default REAPER project directory and searches for `.rpp` files.

Rather than loading each project into REAPER, it reads the project files directly and searches their contents for REAPER's plugin entries.

This has several advantages:

* Projects are not modified.
* Projects do not have to be loaded.
* Missing plugins do not prevent the scan.
* The scan can include projects that cannot currently be opened correctly.
* The process is much faster than opening projects one by one.

Plugin names are extracted from the project files and stored only once, even if the same plugin is used in hundreds of projects.

## Missing or offline plugins

The script deliberately does **not** attempt to determine whether a plugin is currently installed or working.

If a project contains a reference to a plugin that is missing, offline, or has been replaced, the plugin reference is still included in the inventory.

This is intentional.

For example, if a plugin was used in an old project but is no longer installed, it may still be important when rebuilding a system or recovering an old project.

## Progress and cancellation

Large REAPER libraries can contain hundreds or thousands of project files.

The script therefore displays a progress window while scanning.

You can cancel the scan at any time by:

* clicking **STOP**, or
* pressing `Esc`.

If the scan is cancelled, the existing `Project Plugins.txt` file is left untouched.

## Performance

The scanner is designed to handle large project collections efficiently.

For example, during development, a test library containing:

* **305 REAPER projects**
* **17,727 files**
* **253 unique plugins**

was scanned in approximately **3 seconds** on the development system.

The actual scan time will depend on the number and size of project files, the storage device, and the system.

For very large libraries, the scan may still take some time. Do not assume that REAPER has frozen simply because the progress window remains visible for a while.

## Supported plugin formats

The parser currently recognizes REAPER project entries for:

| Format | Status              |
| ------ | ------------------- |
| VST    | Supported           |
| VSTi   | Supported           |
| VST3   | Supported           |
| VST3i  | Supported           |
| CLAP   | Supported           |
| JSFX   | Supported           |
| AU     | Supported by parser |
| DX     | Supported           |

VST/VST3 and DX have been tested on Windows.

CLAP support is also implemented and can be tested with free plugins such as Surge XT.

AU support is implemented in the parser but has not been tested on Windows, since AU is primarily a macOS plugin format.

## Requirements

* REAPER 7.x or later
* Lua ReaScript support
* Windows, macOS or Linux

The script is designed to use standard Lua/ReaScript functionality rather than platform-specific plugin management tools.

## Version

**v1.00**

## License

This project is released under the **MIT License**.

See `LICENSE` for the complete license text.

## Contributing

Bug reports, testing feedback, improvements and suggestions are welcome.

In particular, testing on different operating systems and with different plugin formats would be useful.

If you find a project file containing a plugin format that is not correctly detected, please report it along with the relevant plugin entry from the `.rpp` file if possible.

## Author

Created by **DanloadFR** for the REAPER community.
