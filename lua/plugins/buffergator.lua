-- Buffergator - Sidebar buffer list
-- Custom fork with modifications

return {
    "jerias/vim-buffergator",  -- Your custom fork
    config = function()
        -- Buffergator configuration
        vim.g.buffergator_viewport_split_policy = "L"  -- Open on left side
        vim.g.buffergator_autoexpand_on_split = "L"  -- Open on left side
        vim.g.buffergator_split_size = 30              -- Initial width (autocmd below resizes to content)
        vim.g.buffergator_sort_regime = "filepath"     -- Sort by filepath
        vim.g.buffergator_show_full_directory_path = 0 -- Show relative paths
        vim.g.buffergator_suppress_keymaps = 0         -- Use default keymaps

        -- Dynamically resize to fit the longest line after content renders.
        -- FileType fires before render_buffer(); defer_fn runs after the full
        -- VimScript call stack unwinds, so content is guaranteed to be present.
        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'buffergator',
            callback = function()
                vim.defer_fn(function()
                    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                    local max_width = 0
                    for _, line in ipairs(lines) do
                        -- Line format: [NNN]SSSS<basename_padded>  <parentdir>
                        --   NNN  = right-aligned buffer number (variable digits)
                        --   SSSS = exactly 4 symbol chars (>, #, +, * or spaces)
                        -- Capture only up to the end of the basename, ignoring
                        -- the padding spaces and trailing path.
                        -- Non-matching lines (empty, headers) contribute 0.
                        local prefix_and_name = line:match('^%[%s*%d+%]....%S+')
                        if prefix_and_name then
                            local w = vim.fn.strdisplaywidth(prefix_and_name)
                            max_width = math.max(max_width, w)
                        end
                    end
                    if max_width > 0 then
                        vim.api.nvim_win_set_width(0, max_width + 2)  -- +2 padding
                    end
                end, 0)
            end,
        })
    end,
}
