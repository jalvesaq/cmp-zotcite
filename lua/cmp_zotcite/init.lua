local cmp = require("cmp")
local zc = require("zotcite.config")

local source = {}

local options = { filetypes = { "markdown", "rmd", "quarto", "typst", "vimwiki" } }

source.new = function()
    local self = setmetatable({}, { __index = source })
    return self
end

source.setup = function(opts) options = vim.tbl_extend("force", options, opts or {}) end

source.get_debug_name = function() return "cmp_zotcite" end

source.is_available = function()
    for _, v in pairs(options.filetypes) do
        if vim.bo.filetype == v then return true end
    end
    return false
end

source.resolve = function(_, completion_item, callback)
    vim.schedule(require("zotcite.hl").citations)
    if not completion_item.textEdit then return callback(completion_item) end
    local zkey = string.gsub(completion_item.textEdit.newText, "%-.*", "")
    local ref = vim.fn.py3eval('ZotCite.GetRefData("' .. zkey .. '")')
    if ref then
        local doc = ""
        local ttl = " "
        if ref.title then ttl = ref.title end
        local etype = string.gsub(ref.etype, "([A-Z])", " %1")
        etype = string.lower(etype)
        doc = etype .. "\n\n**" .. ttl .. "**\n\n"
        if ref.etype == "journalArticle" and ref.publicationTitle then
            doc = doc .. "*" .. ref.publicationTitle .. "*\n\n"
        elseif ref.etype == "bookSection" and ref.bookTitle then
            doc = doc .. "In *" .. ref.bookTitle .. "*\n\n"
        end
        if ref.alastnm then doc = doc .. ref.alastnm end
        if ref.year then
            doc = doc .. " (" .. ref.year .. ") "
        else
            doc = doc .. " (????) "
        end
        completion_item.documentation = {
            kind = cmp.lsp.MarkupKind.Markdown,
            value = doc,
        }
    end
    callback(completion_item)
end

source.complete = function(_, request, callback)
    local charb = string.sub(request.context.cursor_before_line, request.offset - 1)
    if string.sub(charb, 1, 1) ~= "@" then return {} end

    local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, true)

    -- Check if we are within normal markdown text
    local lnum = vim.fn.line(".")
    local ismd = true
    for i = lnum, 1, -1 do
        if string.find(lines[i], "^```{") then
            -- within code block
            ismd = false
            break
        else
            if string.find(lines[i], "^```$") then
                -- after a code block
                break
            else
                if
                    (string.find(lines[i], "^---$") or string.find(lines[i], "^%.%.%.$"))
                    and i > 1
                then
                    -- after YAML front matter
                    break
                else
                    if string.find(lines[i], "^---$") and i == 1 then
                        -- within YAML front matter
                        ismd = false
                        break
                    end
                end
            end
        end
    end

    if not ismd then return {} end

    local resp = {}
    local input = string.sub(request.context.cursor_before_line, request.offset)

    -- We have to set the the text edit range because zotcite displays author
    -- names in the menu but inserts a Zotero Key
    local text_edit_range = {
        start = {
            line = request.context.cursor.line,
            character = request.offset - 1,
        },
        ["end"] = {
            line = request.context.cursor.line,
            character = request.context.cursor.character,
        },
    }

    -- Get matching Zotero keys
    local fullfname = vim.fn.expand("%:p")
    if vim.fn.has("win32") == 1 then
        fullfname = string.gsub(tostring(fullfname), "\\", "/")
    end
    if not zc.inited() then zc.init() end
    local itms =
        vim.fn.py3eval('ZotCite.GetMatch("' .. input .. '", "' .. fullfname .. '")')
    if itms then
        for _, v in pairs(itms) do
            local txt = v[2] .. " " .. v[3]
            if vim.fn.strwidth(txt) > 58 then
                txt = vim.fn.strcharpart(txt, 0, 58) .. "⋯"
            end
            table.insert(resp, {
                label = txt,
                kind = cmp.lsp.CompletionItemKind.Reference,
                textEdit = {
                    newText = v[1],
                    range = text_edit_range,
                },
            })
        end
    end
    callback({ items = resp })
end

source.execute = function(_, item, cb)
    vim.schedule(require("zotcite.config").hl_citations)
    cb(item)
end

return source
