# BOTETO - WoW Classic Bot

A modular WoW Classic bot built for Tinkr on macOS.

## Structure

```
/Users/john/dev/boteto/
├── core/
│   ├── state_machine.lua        # State management (15 states)
│   ├── file_management.lua      # File I/O utilities
│   └── combat.lua               # Combat rotation execution
├── test/
│   ├── test_state_machine.lua   # State machine tests (10)
│   ├── test_file_management.lua # File management tests (26)
│   ├── test_bot_core.lua        # Bot core tests (15)
│   ├── test_combat.lua          # Combat tests (20)
│   └── run_all_tests.lua        # Master test runner
├── rotations/                   # Saved rotation files
├── main.lua                     # Main bot logic & GUI
├── COVERAGE_REPORT.md           # Test coverage details
├── TINKR_FILE_API.md            # Tinkr file API docs
└── README.md                    # This file
```

## Loading in WoW

The bot is loaded via a simple skeleton in the Tinkr scripts folder:

```
/tinkr load scripts/wow-boteto.lua
```

The skeleton (`/Users/john/Downloads/tinkr/scripts/wow-boteto.lua`) does two things:
1. Exposes Tinkr filesystem functions as globals
2. Loads `/Users/john/dev/boteto/main.lua`

## Development Workflow

All development happens in `/Users/john/dev/boteto/`. The Tinkr scripts folder only contains the tiny loader.

### Running Tests

```bash
cd /Users/john/dev/boteto/test
lua run_all_tests.lua
```

### Test Coverage

- **71 tests** across 4 test suites
- **95%+ coverage** of testable code
- All tests passing ✅

See `COVERAGE_REPORT.md` for details.

## In-Game Commands

Once loaded in WoW:

```lua
/run StartBot()                      -- Start the bot
/run StopBot()                       -- Stop the bot
/run ToggleGUI()                     -- Show/hide main GUI
/run PrintState()                    -- Print state machine status
/run Combat.PrintRotationStatus()    -- Print rotation status
/run SetBotState(StateMachine.STATES.FIGHTING)
```

## Features

- **State Machine**: 15 states with history tracking
- **Combat System**: Priority-based rotation execution
  - Auto-targeting nearest enemy
  - Spell cooldown tracking
  - GCD detection
  - Resource checking (mana/energy/rage)
  - Cast delay/throttling
- **Rotation Builder**: Drag-and-drop spell rotation editor
- **Rotation Saving**: Save/load rotations to disk
- **GUI**: Main control panel + rotation builder window
- **File I/O**: Read/write rotations and configs

## How to Use

1. **Load the bot** in WoW: `/tinkr load scripts/wow-boteto.lua`
2. **Open Rotation Builder**: Click "Rotation Builder" button in GUI
3. **Build a rotation**: Drag spells from spellbook to rotation builder
4. **Save rotation**: Enter name and click "Save"
5. **Start bot**: Click "Start Bot" button
6. **Fight**: Bot will automatically target and fight nearby enemies using your rotation

## Combat System

The combat module executes rotations using a priority-based system:

### How It Works

1. **Target Selection**: Automatically targets the closest enemy within 40 yards
2. **Priority Loop**: Iterates through rotation spells in order
3. **Spell Validation**: Checks if spell is:
   - Off cooldown (ignores GCD)
   - Usable (has resources, not locked)
   - Not blocked by cast delay (0.5s throttle)
4. **Casting**: Casts first available spell and waits for next update
5. **State Management**: Automatically transitions to FIGHTING state

### Spell Checking Functions

- `Combat.IsSpellOnCooldown(spellId)` - Check cooldown (ignores GCD)
- `Combat.IsSpellUsable(spellId)` - Check if castable
- `Combat.CanCastSpell(spellId, target)` - Full validation
- `Combat.CastSpell(spellId, target)` - Execute cast
- `Combat.IsOnGCD()` - Detect global cooldown
- `Combat.GetHealthPercent()` - Player health percentage
- `Combat.IsInCombat()` - Combat state detection

### Example Rotation

Simple rogue rotation (priority order):
1. Stealth (if out of combat)
2. Sinister Strike (if energy >= 45)
3. Auto-attack

The bot casts the first available spell in the list every update cycle.

## File Loading Pattern

See `TINKR_FILE_API.md` for complete documentation on how Tinkr file loading works.

Key pattern:
```lua
-- In loader (receives Tinkr object)
local Tinkr = ...
_G.ReadFile = function(path) return Tinkr.ReadFile(path) end

-- Everywhere else (use the global)
local code = ReadFile("/Users/john/dev/boteto/module.lua")
local module = (load or loadstring)(code)()
```

## Notes

- All paths use absolute paths to `/Users/john/dev/boteto/`
- Rotation files are saved to `/Users/john/dev/boteto/rotations/`
- GUI code cannot be unit tested (requires WoW API)
- Core logic has 100% test coverage
