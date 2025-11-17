#!/usr/bin/env lua
--[[
    File Management Unit Tests
    Run with: lua test_file_management.lua
]]

-- Mock globals that would be provided by Tinkr
local mockFiles = {}
local mockDirectories = {}

-- Mock WriteFile
function WriteFile(path, content, append)
    if append and mockFiles[path] then
        mockFiles[path] = mockFiles[path] .. content
    else
        mockFiles[path] = content
    end
    return true
end

-- Mock ReadFile
function ReadFile(path)
    return mockFiles[path]
end

-- Mock FileExists
function FileExists(path)
    return mockFiles[path] ~= nil
end

-- Mock DirectoryExists
function DirectoryExists(path)
    return mockDirectories[path] == true
end

-- Mock CreateDirectory
function CreateDirectory(path)
    mockDirectories[path] = true
    return true
end

-- Mock global state
_G = _G or {}
_G.BOTETO_BASE_PATH = "scripts/boteto/"

-- Load the file management module
local FileManagement = {}

-- Write content to a file
function FileManagement.WriteFile(path, content, append)
    local success = WriteFile(path, content, append or false)

    if not success then
        print("[FileManagement] Failed to write file: " .. path)
        return false
    end

    return true
end

-- Read content from a file
function FileManagement.ReadFile(path)
    local content = ReadFile(path)

    if not content then
        print("[FileManagement] Failed to read file: " .. path)
        return nil
    end

    return content
end

-- Check if a file exists
function FileManagement.FileExists(path)
    return FileExists(path)
end

-- Check if a directory exists
function FileManagement.DirectoryExists(path)
    return DirectoryExists(path)
end

-- Create a directory
function FileManagement.CreateDirectory(path)
    return CreateDirectory(path)
end

-- Get the base path for BOTETO
function FileManagement.GetBasePath()
    return _G.BOTETO_BASE_PATH or "scripts/boteto/"
end

-- List files in a directory (mocked for testing)
function FileManagement.ListFiles(path)
    -- In tests, return mock list
    if _G.MOCK_FILE_LISTS and _G.MOCK_FILE_LISTS[path] then
        return _G.MOCK_FILE_LISTS[path]
    end
    return {}
end

-- List subdirectories in a directory (mocked for testing)
function FileManagement.ListDirectories(path)
    -- In tests, return mock list
    if _G.MOCK_DIR_LISTS and _G.MOCK_DIR_LISTS[path] then
        return _G.MOCK_DIR_LISTS[path]
    end
    return {}
end

-- Load a saved rotation
function FileManagement.LoadRotation(rotationName)
    local filePath = FileManagement.GetBasePath() .. "rotations/" .. rotationName .. ".lua"

    local content = FileManagement.ReadFile(filePath)
    if not content then
        return nil
    end

    -- Parse the Lua code (use load for Lua 5.2+, fallback to loadstring for 5.1)
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

    return rotation
end

-- ============================================
-- TEST SUITE
-- ============================================

local testsPassed = 0
local testsFailed = 0

-- Simple assertion helper
local function assert_test(condition, message)
    if not condition then
        error("ASSERTION FAILED: " .. message)
    end
end

-- Helper to run a test
local function runTest(name, testFunc)
    io.write("Testing: " .. name .. " ... ")
    local success, err = pcall(testFunc)
    if success then
        print("✓ PASSED")
        testsPassed = testsPassed + 1
    else
        print("✗ FAILED")
        print("  Error: " .. tostring(err))
        testsFailed = testsFailed + 1
    end
end

-- Reset state before each test
local function resetState()
    mockFiles = {}
    mockDirectories = {}
    _G.BOTETO_BASE_PATH = "scripts/boteto/"
    _G.MOCK_FILE_LISTS = {}
    _G.MOCK_DIR_LISTS = {}
end

print("\n=== Running File Management Unit Tests ===\n")

-- Test 1: WriteFile creates new file
runTest("WriteFile creates new file", function()
    resetState()
    local success = FileManagement.WriteFile("test.txt", "hello", false)
    assert_test(success, "WriteFile should return true")
    assert_test(mockFiles["test.txt"] == "hello", "File should contain 'hello'")
end)

-- Test 2: WriteFile overwrites existing file
runTest("WriteFile overwrites existing file", function()
    resetState()
    FileManagement.WriteFile("test.txt", "first", false)
    FileManagement.WriteFile("test.txt", "second", false)
    assert_test(mockFiles["test.txt"] == "second", "File should contain 'second'")
end)

-- Test 3: WriteFile appends to existing file
runTest("WriteFile appends to existing file", function()
    resetState()
    FileManagement.WriteFile("test.txt", "hello", false)
    FileManagement.WriteFile("test.txt", " world", true)
    assert_test(mockFiles["test.txt"] == "hello world", "File should contain 'hello world'")
end)

-- Test 4: ReadFile returns content
runTest("ReadFile returns content", function()
    resetState()
    mockFiles["test.txt"] = "test content"
    local content = FileManagement.ReadFile("test.txt")
    assert_test(content == "test content", "Should read correct content")
end)

-- Test 5: ReadFile returns nil for non-existent file
runTest("ReadFile returns nil for non-existent file", function()
    resetState()
    local content = FileManagement.ReadFile("nonexistent.txt")
    assert_test(content == nil, "Should return nil for non-existent file")
end)

-- Test 6: FileExists returns true for existing file
runTest("FileExists returns true for existing file", function()
    resetState()
    mockFiles["test.txt"] = "content"
    assert_test(FileManagement.FileExists("test.txt"), "Should return true for existing file")
end)

-- Test 7: FileExists returns false for non-existent file
runTest("FileExists returns false for non-existent file", function()
    resetState()
    assert_test(not FileManagement.FileExists("nonexistent.txt"), "Should return false for non-existent file")
end)

-- Test 8: DirectoryExists returns true for existing directory
runTest("DirectoryExists returns true for existing directory", function()
    resetState()
    mockDirectories["mydir"] = true
    assert_test(FileManagement.DirectoryExists("mydir"), "Should return true for existing directory")
end)

-- Test 9: DirectoryExists returns false for non-existent directory
runTest("DirectoryExists returns false for non-existent directory", function()
    resetState()
    assert_test(not FileManagement.DirectoryExists("nonexistent"), "Should return false for non-existent directory")
end)

-- Test 10: CreateDirectory creates directory
runTest("CreateDirectory creates directory", function()
    resetState()
    local success = FileManagement.CreateDirectory("newdir")
    assert_test(success, "CreateDirectory should return true")
    assert_test(mockDirectories["newdir"] == true, "Directory should be created")
end)

-- Test 11: GetBasePath returns configured path
runTest("GetBasePath returns configured path", function()
    resetState()
    _G.BOTETO_BASE_PATH = "custom/path/"
    assert_test(FileManagement.GetBasePath() == "custom/path/", "Should return custom path")
end)

-- Test 12: GetBasePath returns default when not set
runTest("GetBasePath returns default when not set", function()
    resetState()
    _G.BOTETO_BASE_PATH = nil
    assert_test(FileManagement.GetBasePath() == "scripts/boteto/", "Should return default path")
end)

-- Test 13: LoadRotation loads valid rotation
runTest("LoadRotation loads valid rotation", function()
    resetState()
    local rotationCode = [[
return {
    name = "TestRotation",
    spells = {
        { id = 100, name = "Spell1", icon = "icon1" },
        { id = 200, name = "Spell2", icon = "icon2" }
    }
}
]]
    mockFiles["scripts/boteto/rotations/TestRotation.lua"] = rotationCode

    local rotation = FileManagement.LoadRotation("TestRotation")
    assert_test(rotation ~= nil, "Should load rotation")
    assert_test(rotation.name == "TestRotation", "Should have correct name")
    assert_test(#rotation.spells == 2, "Should have 2 spells")
    assert_test(rotation.spells[1].id == 100, "First spell should have id 100")
end)

-- Test 14: LoadRotation returns nil for non-existent file
runTest("LoadRotation returns nil for non-existent file", function()
    resetState()
    local rotation = FileManagement.LoadRotation("NonExistent")
    assert_test(rotation == nil, "Should return nil for non-existent rotation")
end)

-- Test 15: LoadRotation returns nil for invalid Lua
runTest("LoadRotation returns nil for invalid Lua", function()
    resetState()
    mockFiles["scripts/boteto/rotations/Invalid.lua"] = "this is not valid lua {{"

    local rotation = FileManagement.LoadRotation("Invalid")
    assert_test(rotation == nil, "Should return nil for invalid Lua")
end)

-- Test 16: LoadRotation returns nil for code that errors
runTest("LoadRotation returns nil for code that errors", function()
    resetState()
    mockFiles["scripts/boteto/rotations/Error.lua"] = "error('intentional error')"

    local rotation = FileManagement.LoadRotation("Error")
    assert_test(rotation == nil, "Should return nil for code that errors")
end)

-- Test 17: LoadRotation handles empty rotation
runTest("LoadRotation handles empty rotation", function()
    resetState()
    local rotationCode = [[
return {
    name = "Empty",
    spells = {}
}
]]
    mockFiles["scripts/boteto/rotations/Empty.lua"] = rotationCode

    local rotation = FileManagement.LoadRotation("Empty")
    assert_test(rotation ~= nil, "Should load empty rotation")
    assert_test(#rotation.spells == 0, "Should have 0 spells")
end)

-- Test 18: Multiple writes to same file
runTest("Multiple writes to same file", function()
    resetState()
    FileManagement.WriteFile("test.txt", "1", false)
    FileManagement.WriteFile("test.txt", "2", false)
    FileManagement.WriteFile("test.txt", "3", false)
    assert_test(mockFiles["test.txt"] == "3", "File should contain last write")
end)

-- Test 19: Write and read cycle
runTest("Write and read cycle", function()
    resetState()
    local testContent = "The quick brown fox"
    FileManagement.WriteFile("cycle.txt", testContent, false)
    local readContent = FileManagement.ReadFile("cycle.txt")
    assert_test(readContent == testContent, "Read should match written content")
end)

-- Test 20: LoadRotation with complex rotation
runTest("LoadRotation with complex rotation", function()
    resetState()
    local rotationCode = [[
return {
    name = "ComplexRotation",
    description = "A complex rotation with conditions",
    spells = {
        { id = 1, name = "Spell1", icon = "icon1", condition = "health < 50" },
        { id = 2, name = "Spell2", icon = "icon2", cooldown = 30 },
        { id = 3, name = "Spell3", icon = "icon3", priority = 1 }
    },
    settings = {
        useAOE = true,
        targetCount = 3
    }
}
]]
    mockFiles["scripts/boteto/rotations/ComplexRotation.lua"] = rotationCode

    local rotation = FileManagement.LoadRotation("ComplexRotation")
    assert_test(rotation ~= nil, "Should load complex rotation")
    assert_test(rotation.name == "ComplexRotation", "Should have correct name")
    assert_test(rotation.description ~= nil, "Should have description")
    assert_test(rotation.settings ~= nil, "Should have settings")
    assert_test(rotation.settings.useAOE == true, "Should preserve boolean settings")
    assert_test(rotation.spells[1].condition ~= nil, "Should preserve spell conditions")
end)

-- Test 21: ListFiles returns empty for non-existent directory
runTest("ListFiles returns empty for non-existent directory", function()
    resetState()
    local files = FileManagement.ListFiles("nonexistent/")
    assert_test(#files == 0, "Should return empty table for non-existent directory")
end)

-- Test 22: ListFiles returns file list
runTest("ListFiles returns file list", function()
    resetState()
    _G.MOCK_FILE_LISTS["scripts/rotations/"] = {"rotation1.lua", "rotation2.lua", "rotation3.lua"}
    local files = FileManagement.ListFiles("scripts/rotations/")
    assert_test(#files == 3, "Should return 3 files")
    assert_test(files[1] == "rotation1.lua", "First file should be rotation1.lua")
end)

-- Test 23: ListFiles returns empty for directory with no files
runTest("ListFiles returns empty for directory with no files", function()
    resetState()
    _G.MOCK_FILE_LISTS["empty/"] = {}
    local files = FileManagement.ListFiles("empty/")
    assert_test(#files == 0, "Should return empty table")
end)

-- Test 24: ListDirectories returns empty for non-existent directory
runTest("ListDirectories returns empty for non-existent directory", function()
    resetState()
    local dirs = FileManagement.ListDirectories("nonexistent/")
    assert_test(#dirs == 0, "Should return empty table for non-existent directory")
end)

-- Test 25: ListDirectories returns directory list
runTest("ListDirectories returns directory list", function()
    resetState()
    _G.MOCK_DIR_LISTS["scripts/boteto/"] = {"core", "rotations", "data"}
    local dirs = FileManagement.ListDirectories("scripts/boteto/")
    assert_test(#dirs == 3, "Should return 3 directories")
    assert_test(dirs[1] == "core", "First directory should be core")
end)

-- Test 26: ListDirectories returns empty for directory with no subdirectories
runTest("ListDirectories returns empty for directory with no subdirectories", function()
    resetState()
    _G.MOCK_DIR_LISTS["empty/"] = {}
    local dirs = FileManagement.ListDirectories("empty/")
    assert_test(#dirs == 0, "Should return empty table")
end)

-- Print results
print("\n=== Test Results ===")
print("Passed: " .. testsPassed)
print("Failed: " .. testsFailed)
print("Total: " .. (testsPassed + testsFailed))

if testsFailed == 0 then
    print("\n✓ ALL TESTS PASSED!\n")
    os.exit(0)
else
    print("\n✗ SOME TESTS FAILED!\n")
    os.exit(1)
end
