-- nvim-buffergator: Lua rewrite of vim-buffergator
-- Local plugin at ~/mywcps/other/nvim-buffergator

return {
    "themitchells/nvim-buffergator",
    config = function()
        require("nvim-buffergator").setup({
            width      = 30,
            min_width  = 20,
            max_width  = 60,
            sort       = "filepath",
            auto_resize = true,
            path       = 1,
        })
    end,
}
