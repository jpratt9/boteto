# Bot UI Features Reference

Complete documentation of UI features from reference implementation.

---

## Main Frames/Windows

### 1. MAIN_FRAME_SHORT
**Type:** Main compact frame
**Dimensions:** 225×55 (compact mode) or custom with texture
**Position:** TOPLEFT, UIParent, 23, -120
**Features:**
- Draggable (mouse drag enabled)
- Frame Level: 10
- Background: Custom texture or dialog background
- Contains title text
- Contains stats overlay

**Stats Overlay:**
- Dimensions: 218×40 (compact) or 218×45 (standard)
- Position: TOP of SHORT frame
- Background: Tooltip background with 0.1 alpha
- Text Display: Shows state, XP/H, death count
- Format: `[STATE] | XP/H: [VALUE] | ☠ : [DEATHS]`

### 2. MAIN_FRAME_LONG
**Type:** Extended main frame
**Dimensions:** 220×440 (compact) or 795×800 (standard)
**Position:** Top of SHORT frame
**Background:** Custom texture or dialog background
**Purpose:** Contains all main menu buttons when expanded

### 3. MAIN_FRAME_WQM
**Type:** World Quest Manager frame
**Dimensions:** 500×445 (compact) or 795×800 (standard)
**Position:** Offset from SHORT frame
**Hidden by default**
**Title:** "WQM v0.4"

### 4. MAIN_FRAME_PROFILE_LIBRARY
**Type:** Profile browser window
**Purpose:** Shows available grinding/questing profiles
**Features:**
- Search box for filtering
- Scrollable list
- Category tabs (12 total)

### 5. MAIN_FRAME_CLASS_SETTINGS
**Type:** Class-specific settings window
**Purpose:** Configure class abilities and rotations

### 6. MAIN_FRAME_BOT_SETTINGS
**Type:** General bot settings window
**Purpose:** Configure bot behavior
**Features:** 9 category tabs

### 7. MAIN_FRAME_PAIDPROFILE
**Type:** Premium profile showcase window
**Purpose:** Display paid grinding profiles

### 8. MAIN_FRAME_DEVTOOLS
**Type:** Developer tools window
**Purpose:** Profile creation and testing

### 9. MAIN_FRAME_SUPPORT
**Type:** Support/credits window

---

## Control Buttons (On Main Frame)

### Start/Stop Button
**Size:** 40×40
**Position:** TOPLEFT 99, -155 (or 5, -8 in compact)
**Icon:** Item 7971 texture (compact) or custom start symbol
**Function:** Starts/stops the bot

### Dropdown Button
**Size:** 40×40
**Position:** TOPRIGHT -102, -155 (or -7, -8 in compact)
**Icon:** Item 11855 or dropdown arrow texture
**Function:** Expands/collapses main frame

### Stats Toggle Button
**Size:** 40×40
**Position:** TOP 114, 269 (or 69 in compact)
**Icon:** Item 17364
**Function:** Toggles stats display visibility

### Fishing Button
**Size:** 40×40
**Position:** TOP 114, 315 (or 115 in compact)
**Icon:** Spell 18248 (fishing)
**Function:** Loads fishing profile

### WQM Button
**Size:** 40×40
**Position:** TOP 114, 361 (or 161 in compact)
**Icon:** Spell 347941
**Function:** Toggles World Quest Manager
**Hidden by default**

### Paid Profiles Button
**Size:** 40×40
**Position:** TOP 114, 269
**Icon:** Item 9265
**Function:** Opens paid profiles window
**Hidden by default**

---

## Main Menu Buttons (Vertical List)

### Profile Library Button
**Size:** 211×45 (compact) or 211×200 (standard)
**Position:** TOP 1, -215 (or -53 in compact)
**Texture:** Custom button texture
**Function:** Opens profile library

### Class Settings Button
**Size:** 211×45 (compact) or 211×200 (standard)
**Position:** TOP 1, -255 (or -98 in compact)
**Texture:** Custom button texture
**Function:** Opens class settings

### Bot Settings Button
**Size:** 211×45 (compact) or 211×200 (standard)
**Position:** TOP 1, -295 (or -143 in compact)
**Texture:** Custom button texture
**Function:** Opens bot settings

### Profile Editor Button
**Size:** 211×45 (compact) or 211×200 (standard)
**Texture:** Custom button texture
**Function:** Opens developer tools

### Credits Button
**Size:** 211×45 (compact) or 211×200 (standard)
**Texture:** Custom button texture
**Function:** Opens credits window

---

## Text Displays

### Main Title
**Position:** CENTER 1, -3
**Text:** Bot name
**Font:** MORPHEUS.ttf, size 29

### Stats Text
**Position:** CENTER 0, 6
**Font:** GameFontNormal, size 18
**Content:** State, XP/H, death count
**Format:** `|cff0872B2[STATE]|cffB9B9B9 | XP/H: [VALUE] | ☠ : [DEATHS]`

### Quest Info Text
**Position:** CENTER 0, 29
**Font:** GameFontNormal, size 18
**Content:** Quest information

### Account Stats Label
**Position:** CENTER 0, -65
**Text:** "ACCOUNT STATS"
**Font:** GameFontNormal, size 15

### Character Stats Label
**Position:** CENTER 0, -127
**Text:** "CHARACTER STATS"
**Font:** GameFontNormal, size 15

### State Display
**Position:** CENTER 0, -141
**Text:** "State: IDLE" (colored)
**Font:** GameFontNormal, size 15

### Profile Display
**Position:** CENTER 0, -155
**Text:** "No Profile selected!"
**Font:** GameFontNormal, size 15

### Version Display
**Position:** CENTER 87, -168
**Text:** Version number
**Font:** FRIZQT__.TTF, size 10, OUTLINE

### Account Name Display
**Position:** CENTER 0, -79
**Text:** "Account: [NAME]"
**Font:** GameFontNormal, size 15

### Session ID Display
**Position:** CENTER 0, -95
**Text:** "Session-ID: [ID]"
**Font:** GameFontNormal, size 15

### Session Expiry Display
**Position:** CENTER 0, -110
**Text:** "Expiry Date: [DATE]"
**Font:** GameFontNormal, size 15

---

## Profile Library Components

### 12 Profile Category Tabs

1. **Grinding** - Farm mobs for XP/gold
2. **Questing** - Quest automation
3. **Gathering** - Herb/mining profiles
4. **Dungeons** - Dungeon farming
5. **Battlegrounds** - PVP automation
6. **Task Manager** - Custom task sequences
7. **Crafting** - Profession automation
8. **Traveling** - Travel routes
9. **Automaton** - General automation
10. **Converton** - Converter profiles
11. **Your Profiles** - User-created profiles
12. **Rotation Only** - Combat rotations only

### Components
- **Search box:** Filter profiles by name (150×25)
- **Scroll frame:** Scrollable profile list
- **Dynamic buttons:** Auto-generated for each profile
- **Load button:** Click profile to load it

### Questing Sub-System
- **15-page pagination** for quest profiles
- **Previous button:** Navigate to previous page (20×20, "<")
- **Next button:** Navigate to next page (20×20, ">")
- **Quest settings panel:** 400×185
  - "Ignore Combat when picking up quests" checkbox
  - "Ignore Combat when turning in quests" checkbox

---

## Class Settings Components

### 4 Spell Management Sections

#### Add Spell to Rotation
- **Input box:** Enter spell ID
- **Plus button:** Add spell to rotation
- **Minus button:** Remove spell from rotation

#### Add Healing Spell
- **Input box:** Enter heal spell ID
- **Plus button:** Add to heal rotation
- **Minus button:** Remove from heal rotation

#### Add Buff Spell
- **Input box:** Enter buff spell ID
- **Plus button:** Add to buff rotation
- **Minus button:** Remove from buff rotation

#### Block Spell
- **Input box:** Enter spell ID to blacklist
- **Plus button:** Add to blacklist
- **Minus button:** Remove from blacklist

### Class-Specific Settings (Druid Example)
- **"Always use Stealth"** checkbox
- **"Use Mount instead of Travel Form"** checkbox

---

## Bot Settings Components

### 9 Settings Category Tabs

1. **General**
   - Auto-discover Flight Masters
   - Use Flight Master
   - Pet Battles enable/disable

2. **Gathering**
   - Herb/mining settings

3. **Selling**
   - Auto-sell configuration
   - Vendor settings

4. **Mail**
   - Auto-mail items to alt

5. **Disenchant**
   - Auto-disenchant settings

6. **Blacklisting**
   - Item/mob blacklist management

7. **Inventory Manager**
   - Bag management rules

8. **Relogger**
   - Auto-relog configuration

9. **Security**
   - Anti-ban settings

---

## World Quest Manager (WQM) Components

### Title and Labels
- **Main title:** "WQM v0.4" (MORPHEUS.ttf, size 29)
- **Faction Filter label:** "Faction Filter" (TOP -200, -40)
- **Reward Filter label:** "Reward Filter" (TOP -200, -115)
- **Blacklist label:** "Blacklist Quest Ids" (TOP -155, -200)
- **Whitelist label:** "Whitelist Quest Ids" (TOP -155, -244)
- **Next Profile label:** "Profile to load after WQM" (TOP -90, -305)

### Faction Filter Checkboxes
- ☑ Ascended (TOP -230, -60)
- ☑ Undying Army (TOP -125, -60)
- ☑ Wild Hunt (TOP -230, -80)
- ☑ Court of Harvesters (TOP -125, -80)

### Reward Filter Checkboxes
- ☑ Anima (TOP -230, -140)
- ☑ Gear (TOP -165, -140)
- ☑ Gold (TOP -110, -140)
- ☑ Pet (TOP -140, -160)
- ☑ Reputation (TOP -230, -160)

### Blacklist/Whitelist System
- **Blacklist input box:** 50×30, enter quest IDs to ignore
  - Plus button: Add to blacklist
  - Minus button: Remove from blacklist
  - Print button: Display blacklist
- **Whitelist input box:** Enter quest IDs to prioritize
  - Plus button: Add to whitelist
  - Minus button: Remove from whitelist
  - Print button: Display whitelist

### Next Profile Setting
- **Input box:** Specify profile to load after WQM completes

### Start WQM Button
- **Size:** 73×23
- **Position:** CENTER -100, -185
- **Function:** Initiates World Quest Manager

---

## Battleground System Components

### BG Selection Checkboxes
- ☑ BG 1 through BG 5 (individual battlegrounds)
- ☑ Random BG
- ☑ Epic Random BG

### BG Mode Checkboxes
- ☑ Mode 1
- ☑ Mode 2
- ☑ AFK Mode
- ☑ Queue with opposite faction
- ☑ Grind/Gather while in queue
- ☑ Use local profile

### BG Behavior Settings
- ☑ Roam Mode - Roam around objectives
- ☑ Stealth Mode - Use stealth in BG
- ☑ Assist Mode - Assist teammates
- ☑ Farm Mobs in BG - Kill NPCs

---

## Developer Tools Components

### Profile Creation Checkboxes
- ☑ Include Unstuck Points
- ☑ Include Z Elevation
- ☑ Is Fishing Profile
- ☑ Skip Pulse
- ☑ Skip Turn-in
- ☑ Move Spots

### Tools Panel
- Grind/gather profile recorder
- Waypoint recording system

---

## Slave/Master System Components

### Master Settings Checkboxes
- ☑ Is Master - Designate as master
- ☑ Wait for Slaves - Master waits for slaves
- ☑ Finish Own First - Complete own tasks first
- ☑ Master Can Heal - Enable master healing
- ☑ Announce States - Broadcast state changes
- ☑ Stealth on Death - Use stealth when dead
- ☑ Force Follow Master - Always follow

### Slave Settings
- ☑ Slave is Healer - Healer role designation
- ☑ Block Ghost Walking - Prevent ghost movement

### Master Name Input
- **EditBox:** Enter master character name
- **Target Button:** Auto-fill from target

---

## Premium Profiles Window

### Eternal Grind Buttons
- **Eternal Grind (Horde)** button
- **Eternal Grind (Alliance)** button
- **Load Eternal Profile** button

---

## Visual Styling Elements

### Custom Textures
- MainFrameShortened.blp - Short frame background
- MainFrameLong.blp - Extended frame background
- Custom button texture - Main menu buttons
- Custom button highlighted texture - Button hover state
- DropdownSymbolDown.blp - Dropdown arrow
- DropdownSymbolStart.blp - Start button icon
- UI-Quickslot - Action bar slot texture
- UI-DialogBox-Background-Dark - Dark dialog background
- UI-Tooltip-Background - Tooltip background
- UI-Tooltip-Border - Tooltip border
- UI-Panel-Button-Up/Down/Highlight - Standard button textures
- UI-GroupLoot-Pass-Up - Remove/delete icon
- Arrow-Up-Up - Up arrow
- Arrow-Down-Up - Down arrow

### Color Codes
- `|cff0872B2` - Blue (state, active text)
- `|cffB9B9B9` - Gray (separator)
- `|cffC6C5C3` - Light gray (labels)
- `|cff00ff00` - Green (success)
- `|cffff0000` - Red (error/stopped)

### Fonts
- **MORPHEUS.ttf** (size 18-29) - Titles
- **GameFontNormal** (size 15-18) - Standard text
- **GameFontNormalSmall** - Small text
- **GameFontHighlight** - Highlighted text
- **FRIZQT__.TTF** (size 10, OUTLINE) - Version text

---

## Interactive Features

✓ **Drag and drop** - All main frames movable via mouse drag
✓ **Tooltips** - Hover descriptions on checkboxes
✓ **Pagination** - 15-page quest profile system
✓ **Scroll frames** - Smooth scrolling lists
✓ **Search** - Filter profiles by name
✓ **Tab system** - Category switching
✓ **Dynamic content** - Auto-generated buttons for profiles
✓ **Close buttons** - X button on all windows
✓ **Frame levels** - Hierarchical z-ordering (2-150)
✓ **Show/Hide states** - Toggle visibility with button clicks
✓ **Mutually exclusive panels** - Opening one hides others

---

## Component Count Summary

- **10 major windows**
- **50+ buttons**
- **100+ checkboxes**
- **20+ input boxes**
- **12 profile categories**
- **9 settings tabs**
- **15 pagination frames**
- **Multiple scroll containers**

---

## Stats Display Formats

### Main Stats Bar
```
[STATE] | XP/H: [value] | ☠ : [deaths]
```

### Extended Stats
- Account Stats
- Character Stats
- Current State (colored)
- Profile Name
- Version Number
- Account Name
- Session ID
- Expiry Date
