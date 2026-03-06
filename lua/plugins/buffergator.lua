-- nvim-buffergator: Lua rewrite of vim-buffergator

return {
    "themitchells/nvim-buffergator",
    config = function()
        require("nvim-buffergator").setup({
            width      = 30,
            min_width  = 20,
            max_width  = 120,
            sort       = "filepath",
            auto_resize = true,
            path       = 4,
        })
    end,
}
