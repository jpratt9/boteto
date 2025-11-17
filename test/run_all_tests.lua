#!/usr/bin/env lua
--[[
    Master Test Runner
    Runs all test suites and reports results
    Run with: lua run_all_tests.lua
]]

print("=" .. string.rep("=", 60))
print("  BOTETO Test Suite")
print("=" .. string.rep("=", 60))

local testFiles = {
    "test_state_machine.lua",
    "test_file_management.lua",
    "test_bot_core.lua",
    "test_combat.lua"
}

local totalSuites = #testFiles
local passedSuites = 0
local failedSuites = 0

for i, testFile in ipairs(testFiles) do
    print("\n[" .. i .. "/" .. totalSuites .. "] Running: " .. testFile)
    print(string.rep("-", 62))

    local exitCode = os.execute("lua " .. testFile)

    if exitCode == 0 or exitCode == true then
        passedSuites = passedSuites + 1
        print("\n✓ Suite PASSED: " .. testFile)
    else
        failedSuites = failedSuites + 1
        print("\n✗ Suite FAILED: " .. testFile)
    end
end

print("\n" .. string.rep("=", 62))
print("  FINAL RESULTS")
print(string.rep("=", 62))
print("Test Suites Passed: " .. passedSuites .. "/" .. totalSuites)
print("Test Suites Failed: " .. failedSuites .. "/" .. totalSuites)

if failedSuites == 0 then
    print("\n🎉 ALL TEST SUITES PASSED! 🎉\n")
    os.exit(0)
else
    print("\n❌ SOME TEST SUITES FAILED ❌\n")
    os.exit(1)
end
