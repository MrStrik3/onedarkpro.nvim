local M = {
    lines = {
      -- Structure inside lines
      -- {
      --   text = "",
      --   has_changed = true,
      --   hls = { start_pos = 1, end_pos = 2, hl_name = "" }
      -- }
    },

    win_opts = {
      height = 55,
      width  = 150,
      style = 'minimal'
    },
    win_buf = nil,

    themes = {},
    current_theme_code = nil,
    padding = 2,

-- -------

    currentMode = 0,

    modes = {
        { mode = "colortemplate", text = "Colors", keymap = "C" },
        { mode = "colorpalette", text = "Color palette", keymap = "P" },
        { mode = "alacritty", text = "Alacritty", keymap = "A" },
        { mode = "kitty", text = "Kitty", keymap = "K"},
        { mode = "windowsterminal", text = "Windows Terminal", keymap = "W" },
    },


-------------
}

function M:init2()
  M.lines = {}
    M.win_buf = vim.api.nvim_create_buf(false, true)

    --Set buffer options
    vim.api.nvim_buf_set_option(M.win_buf, "modifiable", true)
    vim.api.nvim_buf_set_option(M.win_buf, "filetype", "Onedarkpro")
    vim.api.nvim_buf_set_option(M.win_buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(M.win_buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(M.win_buf, 'bufhidden', 'wipe')

    local y = vim.o.lines / 2 - M.win_opts["height"] / 2
    local x = vim.o.columns / 2 - M.win_opts["width"] / 2
    local opts = { relative = 'editor', width = M.win_opts["width"], height = M.win_opts["height"], col = x, row = y, anchor = 'NW', style = M.win_opts.style }
    M.window = vim.api.nvim_open_win(M.win_buf, true, opts)
    vim.api.nvim_set_current_win(M.window)

    vim.api.nvim_buf_set_keymap(M.win_buf, 'n', 'q', ":lua require('onedarkpro.utils.colorfloat').close()<cr>", { nowait = true, noremap = true, silent = true })

    M:build_theme_list()
    M.switch_theme(vim.g.colors_name)
    M:set_line(2, "", {})
    M:set_line(3, "", {})

    -- Set keymappings for switching themes
    for _, theme in pairs(M.themes) do
      vim.api.nvim_buf_set_keymap(M.win_buf, 'n', theme.keymap, '', { nowait = true, noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(M.win_buf, 'n', theme.keymap, '<cmd>lua require"onedarkpro.utils.colorfloat".switch_theme("'.. theme.code ..'")<cr>', { nowait = true, noremap = true, silent = true })
    end

    M:switch_template(nil)

    M:render_buffer()

end

function M.switch_theme(theme_code)
  M.current_theme_code = theme_code
  vim.cmd('colorscheme '.. theme_code)
  M:update_theme_menu()
  M:switch_template(nil)
  M:render_buffer()
end

function M:switch_template(template_code)
  M.current_template_code = template_code
  --HERE

  -- local renderedTemplate = require('onedarkpro.utils.colortemplate').render()
    local renderedTemplate = require('onedarkpro.extra.kitty').render()

    local i = 8
    local spacer = string.rep(" ", M.padding)
    for line in renderedTemplate:gmatch("([^\n]*)\n?") do
        -- vim.api.nvim_buf_set_lines(buf, i, (i + 1), false, { line })
        -- M.lines[i] = "  " .. line
        M:set_line(i, spacer .. line, {})
        i = i + 1
    end
end

function M:set_line(no, text, hls)
  hls = hls or nil
  M.lines[no] = { no = no, has_changed = true, text = text, hls = hls }
end

function M:render_buffer()
  -- print(vim.inspect(M.lines))

  local ns_extmark = vim.api.nvim_create_namespace("onedarkprofloat")

  for _, ln in pairs(M.lines) do
    -- print(" --> ".. vim.inspect(ln))
     if ln.has_changed then
       vim.api.nvim_buf_set_lines(M.win_buf, ln.no, -1, false, { ln.text })

       -- add Highlights
       for _, hl in pairs(ln.hls) do
         vim.api.nvim_buf_add_highlight(M.win_buf, ns_extmark, hl.hl_name, ln.no, hl.start_pos, hl.end_pos) -- header
       end
     end
  end
end

function M:build_theme_list()
    local keys = 'sdfgwert'
    local themes = {}
    for i, theme in ipairs(require("onedarkpro.theme").themes) do --> returns { "onedark", "onelight", "onedark_vivid", "onedark_dark" }

      local fmted_theme_name = ' '
      for word in theme:gmatch("([^_]*)_?") do
        if not( word == nil ) and not (word == '') then
          fmted_theme_name = fmted_theme_name .. word:gsub("^%l", string.upper) .. ' '
        end
      end
      themes[i] = { code = theme, text = fmted_theme_name, keymap = string.upper(string.sub(keys, i, i)) }
    end
    M.themes = themes
end

function M:update_theme_menu()
  local hls = {}
  local menu_line = string.rep(" ", M.padding)

  -- Header
  local themes_header = " OneDarkPro.nvim "
  table.insert(hls, { start_pos = string.len(menu_line), end_pos = string.len(themes_header) + string.len(menu_line), hl_name = "TabLineSel" })
  menu_line = menu_line .. themes_header .. "       "

  -- theme lists
  for _, theme in pairs(M.themes) do
    local current_hl_name = "LineNrNC"
    if M.current_theme_code == theme.code then
      current_hl_name = "Visual"
    end

    table.insert(hls, { start_pos = string.len(menu_line) +2, end_pos = string.len(theme.text) + string.len(menu_line) +6, hl_name = current_hl_name })
    menu_line = menu_line .. "  " .. theme.text .. "(".. theme.keymap ..") "
  end

  M:set_line(1, menu_line, hls)
  M:set_line(2, "", {})

end

function M:update_template_menu()

  for _, tmplt in ipairs(M.templates) do
    print(vim.inspect(tmplt))
  end
end

function M:close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
  vim.api.nvim_buf_delete(M.win_buf, {})
  M.lines = {}
end

-- -----------------------------------------

function M:getThemes()
    local themes = {}
    local keys = 'sdfgwert'
    for i, theme in ipairs(require("onedarkpro.theme").themes) do --> returns { "onedark", "onelight", "onedark_vivid", "onedark_dark" }
      themes[i] = { text = theme, keymap = string.upper(string.sub(keys, i, i)) }
    end

    return themes
end

function M:init()

  --- THEME LIST
  --- require("onedarkpro.theme").themes --> returns { "onedark", "onelight", "onedark_vivid", "onedark_dark" }

    M.window_buffer = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_option(M.window_buffer, "modifiable", true)
    vim.api.nvim_buf_set_option(M.window_buffer, "filetype", "Onedarkpro")
    vim.api.nvim_buf_set_option(M.window_buffer, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(M.window_buffer, 'swapfile', false)
    vim.api.nvim_buf_set_option(M.window_buffer, 'bufhidden', 'wipe')

    -- Calculate the upper-left corner coordinate to draw the window at the center of the screen
    local y = vim.o.lines / 2 - M.window_options["height"] / 2
    local x = vim.o.columns / 2 - M.window_options["width"] / 2
    local opts = { relative = 'editor', width = M.window_options["width"], height = M.window_options["height"], col = x, row = y, anchor = 'NW', style = M.window_options.style }
    M.window = vim.api.nvim_open_win(M.window_buffer, true, opts)
    -- vim.api.nvim_win_set_buf(0, M.window_buffer)

    vim.api.nvim_buf_set_keymap(M.window_buffer, 'n', 'q', ":lua require('onedarkpro.utils.colorfloat').close()<cr>", { nowait = true, noremap = true, silent = true })

    M.lines[1] = ""
    M:updateMenu()
    M.lines[5] = ""
    -- M.lines[3] = " ------------------------------------------------------------------------------------------------------------------------------------------ "
    M.lines[6] = ""

    -- local renderedTemplate = require('onedarkpro.utils.colortemplate').render()
    local renderedTemplate = require('onedarkpro.utils.extra.kitty').render()

    local i = 8
    for line in renderedTemplate:gmatch("([^\n]*)\n?") do
        -- vim.api.nvim_buf_set_lines(buf, i, (i + 1), false, { line })
        M.lines[i] = "  " .. line
        i = i + 1
    end
    M.lines[i] = ""
    M.lines[i+1] = ""


    M:render()


    --- idea
    -- if not package.loaded['colrizer'] then
      -- print ("Load Colorizer")
      -- require("colorizer").attach_to_buffer(M.window_buffer, { mode = "virtualtext", names = false })
    -- end
end

return M
