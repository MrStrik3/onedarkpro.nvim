describe("Using the theme", function()
    before_each(function()
        vim.cmd(":e tests/stubs/test.txt")
    end)

    it("Neovim should open with no errors", function()
        local content = vim.fn.getline(1, "$")
        assert.equals("Hello World", content[1])
    end)

    it("it should set a global variable", function()
        assert.equals("onedark_vivid", vim.g.onedarkpro_style)
    end)

    it("it should apply the theme's color palette", function()
        local output = vim.api.nvim_exec("hi Normal", true)
        assert.equals("Normal         xxx guifg=#abb2bf guibg=#282c34", output)
    end)

    it("it should create new colors", function()
        local output = vim.api.nvim_exec("hi Statement", true)
        assert.equals("Statement      xxx ctermfg=11 guifg=#ff00ff", output)
    end)

    it("it should be able to overwrite existing colors", function()
        local output = vim.api.nvim_exec("hi Label", true)
        assert.equals("Label          xxx guifg=#e06c75", output)
    end)

    it("it should be able to overwrite existing hlgroups", function()
        -- Set Repeat to onedark_vivid's blue
        local output = vim.api.nvim_exec("hi Repeat", true)
        assert.equals("Repeat         xxx guifg=#61afef", output)
    end)

    it("it should be able to create custom hlgroups", function()
        local output = vim.api.nvim_exec("hi TestHighlightGroup", true)
        assert.equals("TestHighlightGroup xxx guifg=#e06c75", output)
    end)

    it("it should be able to link to other highlight groups", function()
        local output = vim.api.nvim_exec("hi TestHighlightGroup2", true)
        assert.equals("TestHighlightGroup2 xxx links to Statement", output)
    end)
end)
