--[[
    File Management Module
    Provides file I/O utilities for BOTETO
]]

local FileManagement = {}

-- Write content to a file
-- @param path: string - absolute or relative file path
-- @param content: string - content to write
-- @param append: boolean - if true, append to file; if false, overwrite
-- @return success: boolean
function FileManagement.WriteFile(path, content, append)
    -- Use Tinkr's global WriteFile function
    local success = WriteFile(path, content, append or false)

    if not success then
        print("[FileManagement] Failed to write file: " .. path)
        return false
    end

    return true
end

-- Read content from a file
-- @param path: string - absolute or relative file path
-- @return content: string or nil
function FileManagement.ReadFile(path)
    -- Use ReadFile as global function (same as WriteFile)
    local content = ReadFile(path)

    if not content then
        print("[FileManagement] Failed to read file: " .. path)
        return nil
    end

    return content
end

-- Check if a file exists
-- @param path: string - absolute or relative file path
-- @return exists: boolean
function FileManagement.FileExists(path)
    -- Use Tinkr's global FileExists function
    return FileExists(path)
end

-- Check if a directory exists
-- @param path: string - absolute or relative directory path
-- @return exists: boolean
function FileManagement.DirectoryExists(path)
    -- Use Tinkr's global DirectoryExists function
    return DirectoryExists(path)
end

-- Create a directory
-- @param path: string - absolute or relative directory path
-- @return success: boolean
function FileManagement.CreateDirectory(path)
    -- Use Tinkr's global CreateDirectory function
    return CreateDirectory(path)
end

-- List files in a directory
-- @param path: string - absolute or relative directory path
-- @return files: table of filenames
function FileManagement.ListFiles(path)
    local files = {}

    -- Use popen to run ls command (macOS/Unix)
    -- Note: This is platform-dependent
    local handle = io.popen('ls -1 "' .. path .. '" 2>/dev/null')
    if not handle then
        print("[FileManagement] Failed to list files in: " .. path)
        return files
    end

    for filename in handle:lines() do
        -- Check if it's a file (not a directory)
        local fullPath = path .. "/" .. filename
        local file = io.open(fullPath, "r")
        if file then
            file:close()
            table.insert(files, filename)
        end
    end

    handle:close()
    return files
end

-- List subdirectories in a directory
-- @param path: string - absolute or relative directory path
-- @return directories: table of directory names
function FileManagement.ListDirectories(path)
    local dirs = {}

    -- Use popen to run ls command with directory check
    local handle = io.popen('ls -1 "' .. path .. '" 2>/dev/null')
    if not handle then
        print("[FileManagement] Failed to list directories in: " .. path)
        return dirs
    end

    for name in handle:lines() do
        local fullPath = path .. "/" .. name
        -- Check if it's a directory by trying to list its contents
        local testHandle = io.popen('ls -d "' .. fullPath .. '" 2>/dev/null')
        if testHandle then
            local result = testHandle:read("*line")
            testHandle:close()
            if result and FileManagement.DirectoryExists(fullPath) then
                table.insert(dirs, name)
            end
        end
    end

    handle:close()
    return dirs
end

-- Get the base path for BOTETO (the directory containing this script)
function FileManagement.GetBasePath()
    -- This will be set by main.lua when it loads this module
    return _G.BOTETO_BASE_PATH or "/Users/john/dev/boteto/"
end

-- Load a saved rotation
-- @param rotationName: string - name of rotation (without .lua extension)
-- @return rotation: table or nil
function FileManagement.LoadRotation(rotationName)
    local filePath = FileManagement.GetBasePath() .. "rotations/" .. rotationName .. ".lua"

    print("[FileManagement] Loading rotation from: " .. filePath)

    local content = FileManagement.ReadFile(filePath)
    if not content then
        print("[FileManagement] Failed to read rotation file")
        return nil
    end

    -- Parse the Lua code (use load for Lua 5.2+, fallback to loadstring for 5.1/WoW)
    local loadFunc, loadErr = (load or loadstring)(content)
    if not loadFunc then
        print("[FileManagement] Failed to parse rotation: " .. tostring(loadErr))
        return nil
    end

    local success, rotation = pcall(loadFunc)
    if not success then
        print("[FileManagement] Failed to execute rotation: " .. tostring(rotation))
        return nil
    end

    print("[FileManagement] Successfully loaded rotation: " .. rotationName)
    return rotation
end

return FileManagement
