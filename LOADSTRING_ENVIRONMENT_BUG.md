# LoadString Environment Isolation Bug

## The Bug

When loading main.lua via `loadstring()` from the skeleton (wow-boteto.lua), the loaded code could not access `ReadFile` and other Tinkr functions, even though they were exposed to `_G` in the skeleton.

**Error:**
```
[string "scripts/boteto-dev/main.lua"]:27: attempt to call global 'ReadFile' (a nil value)
```

**Debug output showed:**
```lua
-- In main.lua:
print("[DEBUG] main.lua start - ReadFile type: " .. type(ReadFile))
-- Output: nil

print("[DEBUG] main.lua start - _G.ReadFile type: " .. type(_G.ReadFile))
-- Output: nil

print("[DEBUG] main.lua start - getfenv level: " .. tostring(getfenv(1) == _G))
-- Output: true (main.lua IS using _G as environment)
```

This was confusing because:
1. The skeleton successfully exposed `_G.ReadFile`
2. The skeleton successfully used `ReadFile` itself
3. Main.lua's environment WAS `_G` (getfenv confirmed this)
4. But `_G.ReadFile` was nil in main.lua

## The Root Cause

**In Lua 5.1 (which WoW Classic uses), `loadstring()` creates functions with ISOLATED ENVIRONMENTS by default.**

Each `loadstring()` call creates a function with its own separate `_G` table, even though both are named `_G`. They are different table objects in memory.

**Execution flow:**
```
1. Skeleton receives Tinkr from `/tinkr load`
2. Skeleton exposes functions: _G.ReadFile = function(path) return Tinkr.ReadFile(path) end
   → This sets ReadFile in the SKELETON's _G table
3. Skeleton compiles main.lua: local loadFunc = loadstring(mainCode, mainPath)
   → loadFunc gets a NEW, SEPARATE _G table (not the skeleton's _G)
4. Skeleton executes: pcall(loadFunc, Tinkr)
   → Main.lua executes with its own _G where ReadFile was never set
5. Main.lua tries to call ReadFile() → nil value error
```

**Key insight:** Even though both are called `_G`, they are different table objects:
- `skeleton_G = {ReadFile = function(...), WriteFile = function(...)}`
- `mainlua_G = {}` (empty, no ReadFile)

This is why `getfenv(1) == _G` returned true - main.lua IS using a table named `_G`, just not the SAME `_G` table as the skeleton.

## Why BANETO Works

BANETO doesn't have this problem because it uses a **monolithic architecture**:

- BANETO's entire bot logic is in ONE file (b-src.lua)
- No `loadstring()` is used to load the main bot code
- All code executes in the same environment where Tinkr functions were exposed
- Only uses `loadstring()` for loading rotation profiles (user data), not core code

**BANETO structure:**
```
b-src.lua (receives Tinkr)
├─ Exposes _G.ReadFile, _G.WriteFile, etc.
└─ Contains ALL bot logic inline (no loadstring for main code)
   ├─ State machine code
   ├─ Combat code
   ├─ Looting code
   └─ Everything else
```

**BOTETO structure (broken):**
```
wow-boteto.lua (receives Tinkr)
├─ Exposes _G.ReadFile, _G.WriteFile, etc.
└─ Uses loadstring() to load main.lua
    └─ main.lua (separate _G, no ReadFile!) ✗
        ├─ Uses loadstring() to load state_machine.lua (separate _G!) ✗
        ├─ Uses loadstring() to load combat.lua (separate _G!) ✗
        └─ etc.
```

Each `loadstring()` call creates a new isolated environment.

## The Solution

Use `setfenv()` to force the loaded function to share the skeleton's environment.

**In wow-boteto.lua (after compiling main.lua):**

```lua
local loadFunc, loadErr = loadstring(mainCode, mainPath)
if not loadFunc then
    error("Failed to compile main bot: " .. tostring(loadErr))
end

-- CRITICAL FIX: Force loaded function to use skeleton's environment
setfenv(loadFunc, getfenv())

local success, err = pcall(loadFunc, Tinkr)
```

**What this does:**
- `getfenv()` returns the skeleton's environment table (its `_G`)
- `setfenv(loadFunc, getfenv())` sets the loaded function to use the skeleton's environment
- Now when main.lua executes, it uses the skeleton's `_G` where ReadFile exists

**After the fix:**
```lua
-- In main.lua:
print("[DEBUG] main.lua start - ReadFile type: " .. type(ReadFile))
-- Output: function ✓

print("[DEBUG] main.lua start - _G.ReadFile type: " .. type(_G.ReadFile))
-- Output: function ✓
```

## How Lua 5.1 Environments Work

In Lua 5.1, every function has an **environment table** (accessible via `getfenv`/`setfenv`).

**Default behavior:**
- When you call a function normally, it inherits the caller's environment
- But `loadstring()` creates functions with a NEW environment by default
- This is for security/sandboxing purposes

**Why this wasn't obvious:**
- The Lua 5.1 manual says loadstring "shares the environment of the creating thread"
- But in practice, WoW's Lua implementation creates separate environments
- This might be WoW-specific security sandboxing

**The fix (`setfenv`):**
```lua
-- getfenv() with no args returns current function's environment
local myEnv = getfenv()

-- setfenv(func, table) sets a function's environment
setfenv(loadedFunction, myEnv)

-- Now loadedFunction uses myEnv instead of its own isolated environment
```

## Lessons Learned

1. **loadstring creates isolated environments in WoW's Lua**
   - Don't assume loaded code can see your globals
   - Always use `setfenv()` when loading code that needs access to your environment

2. **Multiple _G tables can exist**
   - Each `loadstring()` call can create a separate `_G` table
   - `getfenv(func) == _G` doesn't mean it's YOUR `_G`

3. **BANETO's monolithic approach avoids this**
   - One file = one environment = no issues
   - But harder to maintain and organize

4. **For modular architecture, use setfenv**
   - Required when using `loadstring()` to load modules
   - Ensures all code shares the same environment

## Pattern to Follow

**When loading modules via loadstring in WoW:**

```lua
-- 1. Expose Tinkr functions to _G
_G.ReadFile = function(path) return Tinkr.ReadFile(path) end
_G.WriteFile = function(path, data, append) return Tinkr.WriteFile(path, data, append) end

-- 2. Load module code
local moduleCode = ReadFile("path/to/module.lua")

-- 3. Compile
local loadFunc, loadErr = loadstring(moduleCode, "module.lua")
if not loadFunc then
    error("Failed to compile: " .. tostring(loadErr))
end

-- 4. CRITICAL: Set environment to share globals
setfenv(loadFunc, getfenv())

-- 5. Execute
local Module = loadFunc()
```

**Without step 4, the loaded module will not see ReadFile or any other globals you set.**

## Alternative Solutions (Not Used)

### Option 1: Monolithic File (BANETO's approach)
- Concatenate all modules into one file before execution
- Pros: No environment issues
- Cons: Hard to maintain, harder to develop/debug

### Option 2: Pass _G Explicitly
```lua
-- In skeleton:
local success, err = pcall(loadFunc, Tinkr, _G)

-- In main.lua:
local Tinkr, SharedG = ...
_G = SharedG  -- Replace our _G with the shared one
```
- Pros: Explicit control
- Cons: Requires modifying loaded code, fragile

### Option 3: Expose Functions via Tinkr Object
```lua
-- In skeleton:
Tinkr.SharedG = _G
pcall(loadFunc, Tinkr)

-- In main.lua:
local Tinkr = ...
ReadFile = Tinkr.SharedG.ReadFile
```
- Pros: Explicit access path
- Cons: Verbose, requires knowing to access via Tinkr

**Why setfenv is best:** Clean, transparent, loaded code doesn't need to know about the environment sharing.

## References

- Lua 5.1 Manual: https://www.lua.org/manual/5.1/manual.html#pdf-setfenv
- WoW API: Uses Lua 5.1 subset
- BANETO source: Monolithic architecture example

## File Location

This bug was discovered and fixed in:
- `/Users/john/Downloads/tinkr/scripts/wow-boteto.lua` (skeleton loader)
- Fix applied at line 79: `setfenv(loadFunc, getfenv())`

Date: 2025-11-17
