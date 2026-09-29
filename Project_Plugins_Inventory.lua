--[[
==============================================================
Project Plugins Inventory
==============================================================

Purpose:
    Recursively scan all REAPER projects (.rpp) located in the
    default REAPER project folder and generate a unique numbered
    list of all plugins referenced by these projects.

Features:
    - Reads .rpp files directly without opening them in REAPER
    - Keeps missing, offline and replaced plugins
    - Removes duplicate plugin names
    - Sorts the result alphabetically
    - Numbers plugins from 001 to 999
    - Creates a single "Project Plugins.txt" file
    - Searches recursively through all subdirectories
    - Displays a centered progress window during the scan
    - Uses large, readable text
    - Provides a STOP button
    - Escape key also stops the scan
    - Does not use the REAPER console

Author:
    danloadFR

Version:
    1.0

Language:
    Lua ReaScript

Compatible with:
    REAPER 7.x
==============================================================
]]


--------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------

local script_start_time = os.clock()

local PATH_SEPARATOR = package.config:sub(1, 1)

local found_plugins = {}

local projects_scanned = 0
local files_checked = 0
local projects_failed = 0

local project_root = nil

local scan_finished = false
local scan_cancelled = false

--------------------------------------------------------------
-- PROGRESS WINDOW SETTINGS
--------------------------------------------------------------

local progress_window_width = 560
local progress_window_height = 190

local title_font_size = 26
local text_font_size = 20

local stop_button_x = 385
local stop_button_y = 135
local stop_button_width = 145
local stop_button_height = 40

local mouse_was_down = false


--------------------------------------------------------------
-- STRING UTILITIES
--------------------------------------------------------------

-- Remove leading and trailing whitespace
local function trim(value)

    if not value then
        return ""
    end

    return value:gsub("^%s+", "")
                :gsub("%s+$", "")

end


-- Remove surrounding double quotes
local function remove_quotes(value)

    if not value then
        return ""
    end

    value = trim(value)

    if value:sub(1, 1) == '"' then
        value = value:sub(2)
    end

    if value:sub(-1) == '"' then
        value = value:sub(1, -2)
    end

    return value

end


--------------------------------------------------------------
-- PLUGIN DATABASE
--------------------------------------------------------------

-- Add a plugin name to the database.
-- Using the plugin name as the table key automatically
-- prevents duplicate entries.

local function add_plugin(plugin_name)

    plugin_name = trim(plugin_name)

    if plugin_name == "" then
        return
    end


    -- Remove REAPER plugin type prefixes.
    --
    -- Examples:
    --     VST3i: Some Instrument
    --     VST3: FabFilter Pro-Q 4
    --     VSTi: Kontakt 8
    --     VST: Some Plugin
    --     CLAP: Some Plugin
    --
    -- Only the actual plugin name is kept.

    plugin_name =
        plugin_name:gsub(
            "^VST3i:%s*",
            ""
        )

    plugin_name =
        plugin_name:gsub(
            "^VST3:%s*",
            ""
        )

    plugin_name =
        plugin_name:gsub(
            "^VSTi:%s*",
            ""
        )

    plugin_name =
        plugin_name:gsub(
            "^VST:%s*",
            ""
        )

    plugin_name =
        plugin_name:gsub(
            "^CLAP:%s*",
            ""
        )

    plugin_name =
        plugin_name:gsub(
            "^AU:%s*",
            ""
        )

    plugin_name =
        plugin_name:gsub(
            "^DX:%s*",
            ""
        )


    plugin_name =
        trim(plugin_name)


    if plugin_name == "" then
        return
    end


    found_plugins[plugin_name] = true

end


--------------------------------------------------------------
-- SORT PLUGIN LIST
--------------------------------------------------------------

local function get_sorted_plugin_list()

    local plugins = {}

    for plugin_name in pairs(found_plugins) do

        table.insert(
            plugins,
            plugin_name
        )

    end

    table.sort(
        plugins,
        function(a, b)
            return a:lower() < b:lower()
        end
    )

    return plugins

end


--------------------------------------------------------------
-- REAPER PROJECT PATH
--------------------------------------------------------------

-- Read the default project folder from reaper.ini.
--
-- REAPER stores this setting as "defsavepath".
-- The older "projpath" key is also supported as a fallback.

local function get_default_project_path()

    local resource_path =
        reaper.GetResourcePath()

    local ini_file =
        resource_path ..
        PATH_SEPARATOR ..
        "reaper.ini"


    local file =
        io.open(ini_file, "r")


    if not file then
        return nil
    end


    for line in file:lines() do

        local path =
            line:match("^defsavepath=(.+)")


        if not path then

            path =
                line:match("^projpath=(.+)")

        end


        if path then

            file:close()

            -- Convert escaped backslashes if present.
            path =
                path:gsub("\\\\", "\\")

            return path

        end

    end


    file:close()

    return nil

end


--------------------------------------------------------------
-- PATH NORMALIZATION
--------------------------------------------------------------

-- Normalize path separators for the current operating system.

local function normalize_path(path)

    if not path then
        return nil
    end

    path =
        path:gsub("[/\\]+", PATH_SEPARATOR)

    return path

end


--------------------------------------------------------------
-- PROJECT FILE TEST
--------------------------------------------------------------

-- Return true only for actual .rpp project files.

local function is_reaper_project(filename)

    if not filename then
        return false
    end

    return filename:lower():match("%.rpp$") ~= nil

end


--------------------------------------------------------------
-- VST PLUGIN PARSER
--------------------------------------------------------------

-- REAPER normally stores VST and VSTi plugins using lines such as:
--
-- <VST "VST3: FabFilter Pro-Q 4 (FabFilter)"
--
-- or:
--
-- <VST "VSTi: Kontakt 8 (Native Instruments)"

local function parse_vst_line(line)

    local plugin =
        line:match('<VST%s+"([^"]+)"')


    if plugin then

        add_plugin(
            remove_quotes(plugin)
        )

        return true

    end


    return false

end


--------------------------------------------------------------
-- CLAP PLUGIN PARSER
--------------------------------------------------------------

local function parse_clap_line(line)

    local plugin =
        line:match('<CLAP%s+"([^"]+)"')


    if plugin then

        add_plugin(
            remove_quotes(plugin)
        )

        return true

    end


    return false

end


--------------------------------------------------------------
-- JSFX PLUGIN PARSER
--------------------------------------------------------------

-- JSFX entries may appear in different forms, for example:
--
-- <JS "utility/volume"
--
-- or:
--
-- <JS Volume Adjustment

local function parse_js_line(line)

    local plugin =
        line:match('<JS%s+"([^"]+)"')


    if not plugin then

        plugin =
            line:match('^<JS%s+(.+)$')

    end


    if plugin then

        plugin =
            remove_quotes(plugin)

        add_plugin(plugin)

        return true

    end


    return false

end


--------------------------------------------------------------
-- AUDIO UNIT PLUGIN PARSER
--------------------------------------------------------------

local function parse_au_line(line)

    local plugin =
        line:match('<AU%s+"([^"]+)"')


    if plugin then

        add_plugin(
            remove_quotes(plugin)
        )

        return true

    end


    return false

end


--------------------------------------------------------------
-- DIRECTX PLUGIN PARSER
--------------------------------------------------------------

local function parse_dx_line(line)

    local plugin =
        line:match('<DX%s+"([^"]+)"')


    if plugin then

        add_plugin(
            remove_quotes(plugin)
        )

        return true

    end


    return false

end


--------------------------------------------------------------
-- GENERIC PLUGIN LINE PARSER
--------------------------------------------------------------

-- Try all supported REAPER plugin formats.

local function parse_plugin_line(line)

    if parse_vst_line(line) then
        return
    end


    if parse_clap_line(line) then
        return
    end


    if parse_js_line(line) then
        return
    end


    if parse_au_line(line) then
        return
    end


    if parse_dx_line(line) then
        return
    end

end


--------------------------------------------------------------
-- PROCESS ONE RPP FILE
--------------------------------------------------------------

local function process_rpp_file(file_path)

    local file =
        io.open(file_path, "r")

    if not file then
        unreadable_projects = unreadable_projects + 1
        return
    end

    -- Read the complete RPP file into memory.

    local content =
        file:read("*a")

    file:close()

    if not content then
        unreadable_projects = unreadable_projects + 1
        return
    end

    -- Scan the file only once for standard plugin formats.
    --
    -- REAPER plugin entries using quoted plugin names:
    --
    --     <VST "VST3: Plugin Name" ...
    --     <CLAP "CLAP: Plugin Name" ...
    --     <AU "AU: Plugin Name" ...
    --     <DX "DX: Plugin Name" ...
    --
    -- The first quoted field contains the plugin name/type.

    for tag, plugin_name in
        content:gmatch('<(%u+)%s+"([^"]+)"')
    do

        if tag == "VST"
        or tag == "CLAP"
        or tag == "AU"
        or tag == "DX"
        then

            add_plugin(plugin_name)

        end

    end

    -- JSFX entries use a different format.
    --
    -- Example:
    --
    --     <JS Liteon/butterworth24db ""
    --
    -- The plugin name is therefore the first non-space field
    -- following <JS, rather than a quoted field.

    for plugin_name in
        content:gmatch('<JS%s+([^%s"]+)')
    do

        add_plugin(plugin_name)

    end

end

--------------------------------------------------------------
-- PROGRESS WINDOW
--------------------------------------------------------------

local function update_progress_window()

    if not gfx.w then
        return
    end


    ----------------------------------------------------------
    -- Clear window
    ----------------------------------------------------------

    gfx.set(
        0.0,
        0.0,
        0.0,
        1.0
    )

    gfx.rect(
        0,
        0,
        gfx.w,
        gfx.h,
        1
    )


    ----------------------------------------------------------
    -- Text color
    ----------------------------------------------------------

    gfx.set(
        1.0,
        1.0,
        1.0,
        1.0
    )


    ----------------------------------------------------------
    -- Title
    ----------------------------------------------------------

    gfx.setfont(
        1,
        "Arial",
        title_font_size
    )

    gfx.x = 30
    gfx.y = 20

    gfx.drawstr(
        "Project Plugins Inventory"
    )


    ----------------------------------------------------------
    -- Status
    ----------------------------------------------------------

    gfx.setfont(
        1,
        "Arial",
        text_font_size
    )

    gfx.x = 30
    gfx.y = 65

    if scan_finished then

        gfx.drawstr(
            "Scan completed."
        )

    elseif scan_cancelled then

        gfx.drawstr(
            "Scan cancelled."
        )

    else

        gfx.drawstr(
            "Scanning projects, please wait..."
        )

    end


    ----------------------------------------------------------
    -- Projects scanned
    ----------------------------------------------------------

    gfx.x = 30
    gfx.y = 105

    gfx.drawstr(
        "Projects scanned: " ..
        tostring(projects_scanned)
    )


    ----------------------------------------------------------
    -- Plugins found
    ----------------------------------------------------------

    gfx.x = 30
    gfx.y = 140

    gfx.drawstr(
        "Unique plugins found: " ..
        tostring(#get_sorted_plugin_list())
    )


    ----------------------------------------------------------
    -- STOP button
    ----------------------------------------------------------

    if not scan_finished and not scan_cancelled then

        -- Button outline
        gfx.set(
            1.0,
            1.0,
            1.0,
            1.0
        )

        gfx.rect(
            stop_button_x,
            stop_button_y,
            stop_button_width,
            stop_button_height,
            0
        )


        -- Button text
        gfx.setfont(
            1,
            "Arial",
            18
        )

        local text = "STOP"

        local text_width =
            gfx.measurestr(text)

        gfx.x =
            stop_button_x +
            (stop_button_width - text_width) / 2

        gfx.y =
            stop_button_y + 9

        gfx.drawstr(text)

    end


    gfx.update()

end


--------------------------------------------------------------
-- INITIALIZE PROGRESS WINDOW
--------------------------------------------------------------

local function open_progress_window()

    -- x = -1 and y = -1 ask REAPER to center the window
    -- on the screen.

    gfx.init(
        "Project Plugins Inventory",
        progress_window_width,
        progress_window_height,
        0,
        -1,
        -1
    )

    gfx.setfont(
        1,
        "Arial",
        text_font_size
    )

    update_progress_window()

end


--------------------------------------------------------------
-- DIRECTORY SCAN STATE
--------------------------------------------------------------

-- Each entry in the stack represents one directory currently
-- being scanned.

local directory_stack = {}


local function push_directory(path)

    table.insert(
        directory_stack,
        {
            path = path,
            file_index = 0,
            subdirectory_index = 0,
            phase = "files"
        }
    )

end


--------------------------------------------------------------
-- CANCEL SCAN
--------------------------------------------------------------

local function cancel_scan()

    if scan_finished then
        return
    end

    scan_cancelled = true

    -- Discard the remaining directory stack.
    directory_stack = {}

    update_progress_window()

end


--------------------------------------------------------------
-- CHECK PROGRESS WINDOW
--------------------------------------------------------------

local function check_progress_window()

    if not gfx.w then
        return false
    end


    ----------------------------------------------------------
    -- Keyboard input
    ----------------------------------------------------------

    local character =
        gfx.getchar()


    -- Escape cancels the scan.

    if character == 27 then

        cancel_scan()

        return false

    end


    -- -1 means that the gfx window was closed.

    if character == -1 then

        scan_cancelled = true

        return false

    end


    ----------------------------------------------------------
    -- Mouse input
    ----------------------------------------------------------

    local mouse_down =
        (gfx.mouse_cap & 1) ~= 0


    if mouse_down and not mouse_was_down then

        local mouse_x =
            gfx.mouse_x

        local mouse_y =
            gfx.mouse_y


        local inside_button =
            mouse_x >= stop_button_x and
            mouse_x <= stop_button_x + stop_button_width and
            mouse_y >= stop_button_y and
            mouse_y <= stop_button_y + stop_button_height


        if inside_button then

            cancel_scan()

            mouse_was_down =
                mouse_down

            return false

        end

    end


    mouse_was_down =
        mouse_down


    return true

end


--------------------------------------------------------------
-- WRITE OUTPUT FILE
--------------------------------------------------------------

local function write_plugin_file(root_folder)

    if not root_folder then

        reaper.ShowMessageBox(
            "Internal error: project root is not defined.",
            "Project Plugins Inventory",
            0
        )

        return false

    end


    local output_file =
        root_folder ..
        PATH_SEPARATOR ..
        "Project Plugins.txt"


    local file =
        io.open(output_file, "w")


    if not file then

        reaper.ShowMessageBox(
            "Unable to create output file:\n\n" ..
            output_file,
            "Project Plugins Inventory",
            0
        )

        return false

    end


    local plugins =
        get_sorted_plugin_list()


    for index, plugin_name in ipairs(plugins) do

        file:write(
            string.format(
                "%04d - %s\n",
                index,
                plugin_name
            )
        )

    end


    file:close()


    return true, output_file, #plugins

end

--------------------------------------------------------------
-- FINAL REPORT
--------------------------------------------------------------

local function finish_scan(root_folder)

    local elapsed =
        os.clock() -
        script_start_time


    local success,
          output_file,
          plugin_count =
        write_plugin_file(root_folder)


    if not success then

        if gfx.w then
            gfx.quit()
        end

        return

    end


    scan_finished = true


    update_progress_window()


    -- Keep the completed progress window visible briefly.

    local finish_time =
        os.clock() + 0.5


    local function show_result()

        if os.clock() < finish_time then

            if gfx.w then
                update_progress_window()
            end

            reaper.defer(
                show_result
            )

            return

        end


        if gfx.w then
            gfx.quit()
        end


        local message =
            "Scan completed.\n\n" ..

            "Projects scanned: " ..
            tostring(projects_scanned) ..
            "\n" ..

            "Files checked: " ..
            tostring(files_checked) ..
            "\n" ..

            "Projects that could not be read: " ..
            tostring(projects_failed) ..
            "\n\n" ..

            "Unique plugins found: " ..
            tostring(plugin_count) ..
            "\n\n" ..

            "Time elapsed: " ..
            string.format("%.2f", elapsed) ..
            " seconds\n\n" ..

            "Output file:\n" ..
            output_file


        reaper.ShowMessageBox(
            message,
            "Project Plugins Inventory",
            0
        )

    end


    reaper.defer(
        show_result
    )

end
--------------------------------------------------------------
-- PROCESS ONE SCAN STEP
--------------------------------------------------------------

local function finish_cancelled_scan()

    local close_time =
        os.clock() + 0.5

    local function close_cancelled_window()

        if os.clock() < close_time then

            if gfx.w then
                update_progress_window()
            end

            reaper.defer(
                close_cancelled_window
            )

            return

        end

        if gfx.w then
            gfx.quit()
        end

        local plugin_count = 0

        for _ in pairs(found_plugins) do
            plugin_count = plugin_count + 1
        end

        reaper.ShowMessageBox(
            "Scan cancelled.\n\n" ..
            "Projects scanned: " ..
            tostring(projects_scanned) ..
            "\n\n" ..
            "Unique plugins found so far: " ..
            tostring(plugin_count) ..
            "\n\n" ..
            "The existing \"Project Plugins.txt\" file " ..
            "was not modified.",
            "Project Plugins Inventory",
            0
        )

    end

    reaper.defer(
        close_cancelled_window
    )

end

local function scan_step()

    ----------------------------------------------------------
    -- Process files for a short time before yielding control
    -- back to REAPER.
    ----------------------------------------------------------

    local batch_start =
        os.clock()

    local batch_duration =
        0.05


    while true do

        ------------------------------------------------------
        -- Check for cancellation.
        ------------------------------------------------------

        if scan_cancelled then

            finish_cancelled_scan()

            return

        end


        ------------------------------------------------------
        -- Check the progress window periodically.
        ------------------------------------------------------

        if os.clock() - batch_start >= batch_duration then

            update_progress_window()

            reaper.defer(
                scan_step
            )

            return

        end


        ------------------------------------------------------
        -- Check whether the user interacted with the window.
        ------------------------------------------------------

        if not check_progress_window() then

            if scan_cancelled then

                finish_cancelled_scan()

            end

            return

        end


        ------------------------------------------------------
        -- Nothing left to scan.
        ------------------------------------------------------

        if #directory_stack == 0 then

            finish_scan(project_root)

            return

        end


        ------------------------------------------------------
        -- Get the current directory.
        ------------------------------------------------------

        local current =
            directory_stack[#directory_stack]


        ------------------------------------------------------
        -- Process files in the current directory.
        ------------------------------------------------------

        if current.phase == "files" then

            local filename =
                reaper.EnumerateFiles(
                    current.path,
                    current.file_index
                )


            if filename then

                current.file_index =
                    current.file_index + 1


                files_checked =
                    files_checked + 1


                if is_reaper_project(filename) then

                    local full_path =
                        current.path ..
                        PATH_SEPARATOR ..
                        filename


                    projects_scanned =
                        projects_scanned + 1


                    process_rpp_file(
                        full_path
                    )

                end


                -- Continue processing files within this batch.

            else

                --------------------------------------------------
                -- No more files: move to subdirectories.
                --------------------------------------------------

                current.phase =
                    "subdirectories"

            end


        else

            ------------------------------------------------------
            -- Process subdirectories.
            ------------------------------------------------------

            local subfolder =
                reaper.EnumerateSubdirectories(
                    current.path,
                    current.subdirectory_index
                )


            if subfolder then

                current.subdirectory_index =
                    current.subdirectory_index + 1


                local full_path =
                    current.path ..
                    PATH_SEPARATOR ..
                    subfolder


                push_directory(
                    full_path
                )

            else

                --------------------------------------------------
                -- Current directory completely scanned.
                --------------------------------------------------

                table.remove(
                    directory_stack
                )

            end

        end

    end

end

--------------------------------------------------------------
-- MAIN PROGRAM
--------------------------------------------------------------

project_root =
    normalize_path(
        get_default_project_path()
    )


if not project_root then

    reaper.ShowMessageBox(
        "Unable to find the default REAPER project folder.\n\n" ..
        "Please check Preferences > Paths.",
        "Project Plugins Inventory",
        0
    )

    return

end


--------------------------------------------------------------
-- Start the asynchronous scan.
--------------------------------------------------------------

open_progress_window()

push_directory(
    project_root
)

reaper.defer(
    scan_step
)


--------------------------------------------------------------
-- END OF SCRIPT
--------------------------------------------------------------
