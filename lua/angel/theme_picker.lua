local M = {}

local config_path = vim.fn.stdpath("config")
local theme_file = config_path .. "/lua/angel/current_theme.lua"

----------------------------------------------------------------
-- Generic preview examples
----------------------------------------------------------------

local examples = {
    lua = {
        'local function greet(name)',
        '    local message = "Hello, " .. name',
        '',
        '    print(message)',
        '',
        '    return {',
        '        name = name,',
        '        active = true,',
        '    }',
        'end',
        '',
        'local user = greet("Ángel")',
        '',
        'if user.active then',
        '    print(user.name)',
        'end',
    },

    python = {
        'def greet(name):',
        '    message = f"Hello, {name}"',
        '',
        '    print(message)',
        '',
        '    return {',
        '        "name": name,',
        '        "active": True,',
        '    }',
        '',
        'user = greet("Ángel")',
        '',
        'if user:',
        '    print(user)',
    },

    cpp = {
        '#include <iostream>',
        '#include <string>',
        '',
        'int main() {',
        '    std::string name = "Ángel";',
        '',
        '    std::cout << "Hello, " << name;',
        '',
        '    for (int i = 0; i < 5; ++i) {',
        '        std::cout << i << std::endl;',
        '    }',
        '',
        '    return 0;',
        '}',
    },

    c = {
        '#include <stdio.h>',
        '',
        'int main(void) {',
        '    const char *name = "Ángel";',
        '',
        '    printf("Hello, %s\\n", name);',
        '',
        '    for (int i = 0; i < 5; i++) {',
        '        printf("%d\\n", i);',
        '    }',
        '',
        '    return 0;',
        '}',
    },

    javascript = {
        'function greet(name) {',
        '    const message = `Hello, ${name}`;',
        '',
        '    console.log(message);',
        '',
        '    return {',
        '        name,',
        '        active: true,',
        '    };',
        '}',
        '',
        'const user = greet("Ángel");',
        '',
        'if (user.active) {',
        '    console.log(user);',
        '}',
    },

    typescript = {
        'interface User {',
        '    name: string;',
        '    active: boolean;',
        '}',
        '',
        'function greet(name: string): User {',
        '    return {',
        '        name,',
        '        active: true,',
        '    };',
        '}',
    },

    html = {
        '<!DOCTYPE html>',
        '<html>',
        '  <head>',
        '    <title>Theme Preview</title>',
        '  </head>',
        '  <body>',
        '    <h1>Hello, Ángel!</h1>',
        '    <p>This is a theme preview.</p>',
        '  </body>',
        '</html>',
    },

    css = {
        'body {',
        '    margin: 0;',
        '    padding: 2rem;',
        '    font-family: sans-serif;',
        '}',
        '',
        '.container {',
        '    display: flex;',
        '    align-items: center;',
        '    gap: 1rem;',
        '}',
        '',
        '.title {',
        '    font-size: 2rem;',
        '    font-weight: bold;',
        '}',
    },

    bash = {
        '#!/bin/bash',
        '',
        'name="Ángel"',
        '',
        'echo "Hello, $name"',
        '',
        'for file in *.txt; do',
        '    echo "Processing: $file"',
        'done',
        '',
        'if [ -f "config.txt" ]; then',
        '    echo "Config found"',
        'fi',
    },

    sh = {
        '#!/bin/sh',
        '',
        'name="Ángel"',
        '',
        'echo "Hello, $name"',
        '',
        'for file in *.txt; do',
        '    echo "Processing: $file"',
        'done',
    },

    rust = {
        'fn greet(name: &str) -> String {',
        '    format!("Hello, {}", name)',
        '}',
        '',
        'fn main() {',
        '    let name = "Ángel";',
        '    let message = greet(name);',
        '',
        '    println!("{}", message);',
        '}',
    },

    go = {
        'package main',
        '',
        'import "fmt"',
        '',
        'func main() {',
        '    name := "Ángel"',
        '    fmt.Println("Hello,", name)',
        '',
        '    for i := 0; i < 5; i++ {',
        '        fmt.Println(i)',
        '    }',
        '}',
    },
}

----------------------------------------------------------------
-- Utility functions
----------------------------------------------------------------

local function get_themes()
    local result = vim.fn.getcompletion("", "color")
    table.sort(result)
    return result
end

local function display_name(name)
    return name:gsub("[-_]", " "):gsub("(%a)([%w]*)", function(a, b)
        return a:upper() .. b
    end)
end

local function truncate(text, width)
    if vim.fn.strdisplaywidth(text) <= width then
        return text
    end

    if width <= 3 then
        return text:sub(1, width)
    end

    return vim.fn.strcharpart(text, 0, width - 3) .. "..."
end

local function read_saved_theme()
    local ok, theme = pcall(dofile, theme_file)

    if ok and type(theme) == "string" then
        return theme
    end

    return nil
end

local function save_theme(theme)
    local file = io.open(theme_file, "w")

    if not file then
        vim.notify(
            "No se pudo guardar el tema",
            vim.log.levels.ERROR
        )
        return false
    end

    file:write('return "' .. theme:gsub('"', '\\"') .. '"\n')
    file:close()

    return true
end

local function contains_text(lines)
    for _, line in ipairs(lines) do
        if line:match("%S") then
            return true
        end
    end

    return false
end

----------------------------------------------------------------
-- Get code for preview
----------------------------------------------------------------

local function get_preview()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()

    local filetype = vim.bo[buf].filetype
    local buftype = vim.bo[buf].buftype
    local filename = vim.fn.expand("%:t")

    if filename == "" then
        filename = "[No Name]"
    end

    local cursor_line = 1

    if vim.api.nvim_win_is_valid(win) then
        cursor_line = vim.api.nvim_win_get_cursor(win)[1]
    end

    ------------------------------------------------------------
    -- Real current file
    ------------------------------------------------------------

    if buftype == "" then
        local total = vim.api.nvim_buf_line_count(buf)

        if total > 0 then
            local start = math.max(cursor_line - 9, 0)
            local finish = math.min(start + 18, total)

            if finish - start < 18 then
                start = math.max(finish - 18, 0)
            end

            local lines = vim.api.nvim_buf_get_lines(
                buf,
                start,
                finish,
                false
            )

            if contains_text(lines) then
                return {
                    lines = lines,
                    filetype = filetype,
                    filename = filename,
                    source = "current file",
                }
            end
        end
    end

    ------------------------------------------------------------
    -- Generic example
    ------------------------------------------------------------

    if examples[filetype] then
        return {
            lines = examples[filetype],
            filetype = filetype,
            filename = filename,
            source = "example",
        }
    end

    ------------------------------------------------------------
    -- Fallback
    ------------------------------------------------------------

    return {
        lines = examples.lua,
        filetype = "lua",
        filename = filename,
        source = "example",
    }
end

----------------------------------------------------------------
-- Filter
----------------------------------------------------------------

local function filter_themes(themes, query)
    if query == "" then
        return vim.deepcopy(themes)
    end

    local result = {}
    local lower_query = query:lower()

    for _, theme in ipairs(themes) do
        if theme:lower():find(lower_query, 1, true) then
            table.insert(result, theme)
        end
    end

    return result
end

----------------------------------------------------------------
-- Main picker
----------------------------------------------------------------

function M.open()
    local all_themes = get_themes()

    if #all_themes == 0 then
        vim.notify(
            "No se encontraron colorschemes",
            vim.log.levels.WARN
        )
        return
    end

    local previous_theme = vim.g.colors_name
    local saved_theme = read_saved_theme()

    local themes = vim.deepcopy(all_themes)
    local selected = 1
    local filter = ""

    for i, theme in ipairs(themes) do
        if theme == previous_theme then
            selected = i
            break
        end
    end

    local preview = get_preview()

    ------------------------------------------------------------
    -- Layout
    ------------------------------------------------------------

    local ui = vim.api.nvim_list_uis()[1]

    local total_width = math.min(96, ui.width - 4)
    local list_width = math.min(32, math.floor(total_width * 0.34))
    local gap = 1
    local preview_width = total_width - list_width - gap

    local height = math.min(
        18,
        math.max(8, ui.height - 10)
    )

    local row = math.max(
        1,
        math.floor((ui.height - height - 5) / 2)
    )

    local col = math.max(
        1,
        math.floor((ui.width - total_width) / 2)
    )

    ------------------------------------------------------------
    -- Buffers
    ------------------------------------------------------------

    local list_buf = vim.api.nvim_create_buf(false, true)
    local preview_buf = vim.api.nvim_create_buf(false, true)
    local footer_buf = vim.api.nvim_create_buf(false, true)

    for _, buf in ipairs({
        list_buf,
        preview_buf,
        footer_buf,
    }) do
        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].bufhidden = "wipe"
        vim.bo[buf].swapfile = false
    end

    ------------------------------------------------------------
    -- Windows
    ------------------------------------------------------------

    local list_win = vim.api.nvim_open_win(
        list_buf,
        true,
        {
            relative = "editor",
            width = list_width,
            height = height,
            row = row,
            col = col,
            style = "minimal",
            border = "rounded",
            title = " Themes ",
            title_pos = "center",
        }
    )

    local preview_win = vim.api.nvim_open_win(
        preview_buf,
        false,
        {
            relative = "editor",
            width = preview_width,
            height = height,
            row = row,
            col = col + list_width + gap,
            style = "minimal",
            border = "rounded",
            title = " Preview ",
            title_pos = "center",
        }
    )

    local footer_win = vim.api.nvim_open_win(
        footer_buf,
        false,
        {
            relative = "editor",
            width = total_width,
            height = 2,
            row = row + height + 1,
            col = col,
            style = "minimal",
            border = "rounded",
        }
    )

    ------------------------------------------------------------
    -- Window options
    ------------------------------------------------------------

    vim.wo[list_win].wrap = false
    vim.wo[list_win].cursorline = false
    vim.wo[list_win].signcolumn = "no"

    vim.wo[preview_win].wrap = false
    vim.wo[preview_win].number = true
    vim.wo[preview_win].relativenumber = false
    vim.wo[preview_win].signcolumn = "no"
    vim.wo[preview_win].cursorline = false

    vim.wo[footer_win].wrap = false

    ------------------------------------------------------------
    -- Preview contents
    ------------------------------------------------------------

    vim.api.nvim_buf_set_lines(
        preview_buf,
        0,
        -1,
        false,
        preview.lines
    )

    vim.bo[preview_buf].filetype = preview.filetype
    vim.bo[preview_buf].modifiable = false

    ------------------------------------------------------------
    -- Cursor
    ------------------------------------------------------------

    local old_guicursor = vim.o.guicursor

    local function hide_cursor()
        vim.o.guicursor = "a:Cursor"

        local normal = vim.api.nvim_get_hl(0, {
            name = "Normal",
            link = false,
        })

        if normal.bg then
            vim.api.nvim_set_hl(0, "Cursor", {
                fg = normal.bg,
                bg = normal.bg,
            })
        end
    end

    local function restore_cursor()
        vim.o.guicursor = old_guicursor
    end

    ------------------------------------------------------------
    -- Highlight groups
    ------------------------------------------------------------

    local function setup_highlights()
        vim.api.nvim_set_hl(0, "ThemePickerSelected", {
            link = "PmenuSel",
        })

        vim.api.nvim_set_hl(0, "ThemePickerMeta", {
            link = "Comment",
        })

        vim.api.nvim_set_hl(0, "ThemePickerSaved", {
            link = "DiagnosticOk",
        })
    end

    ------------------------------------------------------------
    -- Footer
    ------------------------------------------------------------

    local function update_footer()
        local position = string.format(
            "%d / %d",
            selected,
            #themes
        )

        local source = preview.source
            .. " · "
            .. preview.filename

        local line1 = truncate(
            position .. "  ·  " .. source,
            total_width - 2
        )

        local line2 = truncate(
            "j/k ↑↓ move · / filter · c clear · r refresh · Enter apply · Esc/q cancel",
            total_width - 2
        )

        vim.api.nvim_buf_set_lines(
            footer_buf,
            0,
            -1,
            false,
            {
                line1,
                line2,
            }
        )

        vim.api.nvim_buf_clear_namespace(
            footer_buf,
            -1,
            0,
            -1
        )

        vim.api.nvim_buf_add_highlight(
            footer_buf,
            -1,
            "ThemePickerMeta",
            0,
            0,
            -1
        )

        vim.api.nvim_buf_add_highlight(
            footer_buf,
            -1,
            "ThemePickerMeta",
            1,
            0,
            -1
        )
    end

    ------------------------------------------------------------
    -- List
    ------------------------------------------------------------

    local function render_list()
        local lines = {}

        if #themes == 0 then
            lines = {
                "  No themes found",
            }
        else
            for i, theme in ipairs(themes) do
                local marker = "  "

                if i == selected then
                    marker = "› "
                end

                local suffix = ""

                if theme == saved_theme then
                    suffix = " [saved]"
                end

                local available =
                    list_width
                    - vim.fn.strdisplaywidth(marker)
                    - vim.fn.strdisplaywidth(suffix)
                    - 1

                local name = truncate(
                    display_name(theme),
                    available
                )

                table.insert(
                    lines,
                    marker .. name .. suffix
                )
            end
        end

        vim.api.nvim_buf_set_lines(
            list_buf,
            0,
            -1,
            false,
            lines
        )

        vim.api.nvim_buf_clear_namespace(
            list_buf,
            -1,
            0,
            -1
        )

        if #themes > 0 then
            vim.api.nvim_buf_add_highlight(
                list_buf,
                -1,
                "ThemePickerSelected",
                selected - 1,
                0,
                -1
            )
        end

        if #themes > 0 then
            vim.api.nvim_win_set_cursor(
                list_win,
                {
                    selected,
                    0,
                }
            )
        end
    end

    ------------------------------------------------------------
    -- Preview title
    ------------------------------------------------------------

    local function update_title()
        if not vim.api.nvim_win_is_valid(preview_win) then
            return
        end

        local theme = themes[selected]

        if not theme then
            theme = "Preview"
        end

        vim.api.nvim_win_set_config(
            preview_win,
            {
                title = " "
                    .. display_name(theme)
                    .. " · "
                    .. preview.filetype
                    .. " ",
                title_pos = "center",
            }
        )
    end

    ------------------------------------------------------------
    -- Apply preview
    ------------------------------------------------------------

    local function preview_theme()
        if #themes == 0 then
            return
        end

        pcall(
            vim.cmd.colorscheme,
            themes[selected]
        )

        setup_highlights()
        render_list()
        update_title()
        update_footer()
        hide_cursor()
    end

    ------------------------------------------------------------
    -- Complete redraw
    ------------------------------------------------------------

    local function redraw()
        setup_highlights()
        render_list()
        update_title()
        update_footer()
        hide_cursor()
    end

    ------------------------------------------------------------
    -- Close
    ------------------------------------------------------------

    local closed = false

    local function close(restore)
        if closed then
            return
        end

        closed = true

        if restore and previous_theme then
            pcall(
                vim.cmd.colorscheme,
                previous_theme
            )
        end

        if vim.api.nvim_win_is_valid(list_win) then
            vim.api.nvim_win_close(list_win, true)
        end

        if vim.api.nvim_win_is_valid(preview_win) then
            vim.api.nvim_win_close(preview_win, true)
        end

        if vim.api.nvim_win_is_valid(footer_win) then
            vim.api.nvim_win_close(footer_win, true)
        end

        restore_cursor()
    end

    ------------------------------------------------------------
    -- Movement
    ------------------------------------------------------------

    local function move(amount)
        if #themes == 0 then
            return
        end

        selected = selected + amount

        if selected < 1 then
            selected = #themes
        elseif selected > #themes then
            selected = 1
        end

        preview_theme()
    end

    ------------------------------------------------------------
    -- Filter
    ------------------------------------------------------------

    local function filter_prompt()
        vim.ui.input(
            {
                prompt = "Theme filter: ",
                default = filter,
            },
            function(input)
                if input == nil or closed then
                    return
                end

                filter = input

                local old_theme = themes[selected]

                themes = filter_themes(
                    all_themes,
                    filter
                )

                selected = 1

                for i, theme in ipairs(themes) do
                    if theme == old_theme then
                        selected = i
                        break
                    end
                end

                if #themes > 0 then
                    preview_theme()
                else
                    redraw()
                end
            end
        )
    end

    ------------------------------------------------------------
    -- Clear filter
    ------------------------------------------------------------

    local function clear_filter()
        filter = ""
        themes = vim.deepcopy(all_themes)

        selected = 1

        for i, theme in ipairs(themes) do
            if theme == previous_theme then
                selected = i
                break
            end
        end

        preview_theme()
    end

    ------------------------------------------------------------
    -- Refresh themes
    ------------------------------------------------------------

    local function refresh()
        all_themes = get_themes()

        themes = filter_themes(
            all_themes,
            filter
        )

        if selected > #themes then
            selected = math.max(1, #themes)
        end

        if #themes > 0 then
            preview_theme()
        else
            redraw()
        end
    end

    ------------------------------------------------------------
    -- Keymaps
    ------------------------------------------------------------

    local opts = {
        buffer = list_buf,
        silent = true,
        nowait = true,
    }

    vim.keymap.set("n", "j", function()
        move(1)
    end, opts)

    vim.keymap.set("n", "k", function()
        move(-1)
    end, opts)

    vim.keymap.set("n", "<Down>", function()
        move(1)
    end, opts)

    vim.keymap.set("n", "<Up>", function()
        move(-1)
    end, opts)

    vim.keymap.set("n", "<C-d>", function()
        move(math.max(1, math.floor(height / 2)))
    end, opts)

    vim.keymap.set("n", "<C-u>", function()
        move(-math.max(1, math.floor(height / 2)))
    end, opts)

    vim.keymap.set("n", "gg", function()
        if #themes > 0 then
            selected = 1
            preview_theme()
        end
    end, opts)

    vim.keymap.set("n", "G", function()
        if #themes > 0 then
            selected = #themes
            preview_theme()
        end
    end, opts)

    vim.keymap.set("n", "/", filter_prompt, opts)

    vim.keymap.set("n", "c", clear_filter, opts)

    vim.keymap.set("n", "r", refresh, opts)

    ------------------------------------------------------------
    -- Apply
    ------------------------------------------------------------

    vim.keymap.set("n", "<CR>", function()
        if #themes == 0 then
            return
        end

        local chosen = themes[selected]

        if save_theme(chosen) then
            saved_theme = chosen
            close(false)

            vim.notify(
                "Tema guardado: " .. chosen,
                vim.log.levels.INFO
            )
        end
    end, opts)

    ------------------------------------------------------------
    -- Cancel
    ------------------------------------------------------------

    local function cancel()
        close(true)
    end

    vim.keymap.set("n", "<Esc>", cancel, opts)
    vim.keymap.set("n", "q", cancel, opts)
    vim.keymap.set("n", "<C-c>", cancel, opts)

    ------------------------------------------------------------
    -- Start
    ------------------------------------------------------------

    hide_cursor()
    setup_highlights()
    render_list()
    update_title()
    update_footer()

    if #themes > 0 then
        pcall(
            vim.cmd.colorscheme,
            themes[selected]
        )

        setup_highlights()
        render_list()
        update_title()
        update_footer()
        hide_cursor()
    end
end

return M
