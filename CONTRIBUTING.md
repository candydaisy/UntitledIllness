# Helping with Untitled Illness

Thanks for helping! This page tells you where things are and how not to break them.

## Setup

1. Install **Godot 4.7** (the standard version, not .NET).
2. Clone the repo and open `project.godot` in Godot.
3. Press **F5** to play.

## Where things are

```
UntitledIllness/
├── Story/                      Dialogue and branching, one folder per character
│   ├── README.md             How to write story nodes (start here if you're writing)
│   ├── Canon_Timeline.md     What actually happens, across every route
│   ├── relationships.json    Characters and links for the relationship web (Gallery)
│   ├── Characters/           Who each character is and how they see the world
│   └── Kay/, Elysia/, Ulyn/  flow_graph.json (what the game plays) + *_Story.md (the same story as prose)
│
├── Scenes/                     Godot scenes, each next to its script
│   ├── Menus/                Splash screen, title menu, character select, settings/save menu
│   ├── Dialog/               The dialogue box, choice buttons, Auto / Log / Menu buttons
│   └── Characters/           One story scene per character (Kay.tscn, Elysia.tscn, Ulyn.tscn)
│
├── Scripts/StoryEngine/        The code that plays a story (shared by all characters)
│   ├── story_player.gd       Main script, attached to each character's story scene
│   ├── modes/                How each character plays (meters, effects, choice rules)
│   │   ├── story_mode.gd     The base every mode builds on
│   │   ├── kay_mode.gd
│   │   ├── elysia_mode.gd
│   │   └── ulyn_mode.gd
│   ├── flow_graph.gd         Loads the story JSON, checks links, evaluates secrets
│   ├── emotional_weight.gd   Kay's Emotional Weight value and LOW/MEDIUM/HIGH/CRITICAL
│   ├── typewriter.gd         Typing effect, sounds, and self-editing (type, delete, retype)
│   ├── dialog_log.gd         The Log window
│   ├── phone_popup.gd        Incoming calls ("call" nodes)
│   ├── save_game.gd          Save slots in user://saves/
│   ├── accessibility.gd      Screen reader helpers (spoken lines, focus, announcements)
│   ├── story_stage.gd        Backgrounds, characters, fades
│   └── story_audio.gd        Sound effect / ambience / voice list
│
├── Assets/                     Art, audio, fonts, themes
│   ├── Photos/Background/    Backgrounds
│   ├── Photos/Sprites/       Character sprites
│   ├── Photos/UI/            Menu and side art
│   ├── audio/sfx/            Sound effects
│   ├── audio/amb/            Looping ambience
│   ├── audio/voice/          Voice lines (create it when the first one arrives)
│   ├── audio/ui/             Typing sound
│   ├── Fonts/
│   ├── Shaders/              sideart_tint: recolors the butterfly side art per character
│   └── Themes/               theme1 (title screen), kay_theme, elysia_theme
│
└── Docs/                     Project write-ups
```

## What do you want to do?

**Write or edit dialogue** → read [`Story/README.md`](Story/README.md), then edit the character's `flow_graph.json`. No code needed.

**Translate dialogue** → edit the character's `th.json` (see [Translations](Story/README.md#translations-thai)). Menu text is in `Translations/ui.csv`.

You can also use **[TTFUI](https://github.com/candydaisy/TTFUI)** ([open it in the browser](https://candydaisy.github.io/TTFUI/)), a visual editor for these files:
- **Flow graph editor:** import a `flow_graph.json`, edit it as a node graph, playtest it with the character's real rules (meters, locks, timed choices, self-edits), and export. Exporting an unchanged story gives back the identical file.
- **Relationship web editor** (the **Relationships** button): edits `Story/relationships.json`. **Open Story Folder** checks every story for speakers missing from the web.

**Add a background**
1. Put the image in `Assets/Photos/Background/`.
2. Open the character's scene in `Scenes/Characters/`, add a `TextureRect` under **Bgs**, and set its texture.
3. The node's name is what you write in `"background"` in the story file.

**Add a character sprite / expression**
1. Put images in `Assets/Photos/Sprites/`.
2. In the character's scene, select the sprite under **Characters** and add animations to its SpriteFrames. The animation name is what you write in `"expression"`.

**Add a sound**
1. Put the file in `Assets/audio/sfx/` (or `amb/` for loops, `voice/` for voice lines).
2. Add a line for it in `SFX` (or `AMB`, `VOICE`) in `Scripts/StoryEngine/story_audio.gd`.

**Add a new character's story**
1. Write `Story/<Name>/<Name>_Story.md` first, then turn it into `Story/<Name>/flow_graph.json` (see [Story file structure](#story-file-structure)).
2. Pick a mode. Reuse one (`KayMode`, `ElysiaMode`), or write a new one (see [Character modes](#character-modes)).
3. Duplicate `Scenes/Characters/Kay.tscn` in Godot's FileSystem panel and rename it.
4. Select the root node. In the Inspector, set **Flow Graph Path**, **Start Node** (usually `start`), and **Mode** (click it → New *YourMode*). The mode's numbers show up underneath, ready to tune.
5. Swap in that character's backgrounds and sprites.
6. Give them their own look:
   - **UI Theme** (on the root node): duplicate `Assets/Themes/kay_theme.tres`, change its colors, and set it here. It styles the dialog box, buttons, log and in-game menu.
   - **Side art color**: select the **Sideart** node, open its **Material**, and set **Tint**. Each scene has its own copy of the material, so this only changes this character.
7. Put the scene's path in `STORY_SCENES` in `Scenes/Menus/selections.gd`, at the same position as the character's button.
8. Press F5. Godot's Output panel warns about anything in the story the scene or mode doesn't know.

## Story file structure

A story is one JSON object. Each key is a node id, and each value is one line of the story. The game starts at the scene's **Start Node** and follows `next`. A node with no `next` and no `choices` ends the story.

```json
{
	"start": {
		"speaker": "Kay",
		"emotion": "tired",
		"text": "Monday...",
		"next": "wake_2",
		"background": "Kay's room1",
		"show_characters": ["Kay"],
		"sfx": "Alarm"
	},

	"wake_2": {
		"speaker": "Kay",
		"text": "What should I do first?",
		"choices": [
			{"text": "Take a nap", "type": "neutral", "weight_change": 5, "next": "nap_1"},
			{"text": "Get up", "type": "honest", "weight_change": -5, "next": "up_1", "set_flag": "GotUp"}
		]
	},

	"nap_1": {
		"speaker": "",
		"text": "*He sleeps through first period.*",
		"next": "school_1",
		"secret": {"condition": "flag_true", "flag": "GotUp", "next": "other_1"}
	}
}
```

### Node keys (every character)

| Key | Type | Meaning |
|---|---|---|
| `speaker` | string | Name on the name plate. `""` for narration. |
| `text` | string | The line. Conventions: narration in `*asterisks*`, speech in `"quotes"`, thoughts and text messages bare. |
| `next` | string | Id of the next node. Leave out on a choice node or the last node. |
| `emotion` | string | Typing speed: `angry`, `nervous`, `tired`, `sad`. |
| `choices` | array | Up to 3 choices (see below). Use instead of `next`. |
| `secret` | object | Jump somewhere else after this node if a condition is true (see below). One per node. |
| `background` | string | Name of a node under **Bgs** in the scene. |
| `show_characters` / `hide_characters` | array of strings | Names of nodes under **Characters**. |
| `expression` | object | `{"Kay": "School"}` plays that sprite animation. |
| `sfx` / `amb` / `voice` | string | A name from `story_audio.gd`. `sfx` and `amb` also take `"stop"`. |
| `call` | string | Shows the node's choices on a ringing phone from this caller, e.g. `"Mom"`. |

Inside `text`, `{shown text|FlagName}` is a detail the player can click to notice; it sets `FlagName`.

### Choice keys (every character)

| Key | Type | Meaning |
|---|---|---|
| `text` | string | Button label. |
| `type` | string | What kind of answer it is. Which types exist depends on the mode. |
| `next` | string | Node to go to. |
| `set_flag` | string | Remembers this choice for a later `secret` or `requires`. Flags are true/false, set by choices or by noticing a detail. |
| `requires` | string | Only show this choice if this flag is set (e.g. the player noticed something). |

### Secrets

```json
"secret": {"condition": "flag_true", "flag": "GotUp", "next": "other_1"}
"secret": {"condition": "weight_below", "value": 35, "next": "endA_1"}
```

`flag_true` / `flag_false` test a flag. `<meter>_above` / `<meter>_below` test one of the mode's meters (Kay: `weight`; Elysia: `mask`, `energy`; Ulyn: `busy`, `unsaid`). A secret only has one condition. For two conditions, chain two nodes, each with its own secret.

### Mode keys

Each mode adds its own keys. These are listed in its `INFO` (see below) and in [`Story/README.md`](Story/README.md).

| Mode | Choice keys | Node keys | Choice types |
|---|---|---|---|
| KayMode | `weight_change` | | `neutral`, `honest`, `helpful` |
| ElysiaMode | `mask_change`, `energy_change` | `real_text`, `timed` | `neutral`, `honest`, `helpful`, `perform` |
| UlynMode | `busy_change`, `unsaid_change` | `cut`, `cut_after`, `quiet` | `neutral`, `honest`, `helpful`, `open` |

## Relationship web

The **Gallery** screen shows every character as a graph, like Obsidian's graph view. All of it comes from `Story/relationships.json`; the scene (`Scenes/Menus/RelationshipWeb.tscn`) has no names in it.

```json
{
	"ignore_speakers": ["", "???", "Teacher", "Lunch Lady"],
	"characters": [
		{"id": "Kay", "name": "Kay", "playable": true, "color": "#5980ff", "picture": "", "about": "Grade 11. Carries everything."},
		{"id": "KayMom", "name": "Kay's Mom", "speaker": "Mom", "route": "Kay", "picture": "", "about": "Hospital shifts, always tired."}
	],
	"links": [
		{"from": "Kay", "to": "KayMom", "to_is": "mom", "from_is": "son"}
	]
}
```

| Key | Meaning |
|---|---|
| `id` | Unique id used by links. |
| `name` | Shown in the web. |
| `playable` / `color` | Playable characters are drawn in their color (match it to their side art and theme). Everyone else is grey. |
| `picture` | `res://` path to their picture. Empty = a big colored initial until the art exists. |
| `about` | One or two sentences for the side panel. |
| `speaker` | Their name in the story files, if it isn't `name` (e.g. `"Mom"`). |
| `route` | Only match `speaker` in this character's story. Needed when the same speaker name is a different person in each story. |
| `to_is` / `from_is` | What `to` is to `from`, and what `from` is to `to`. Clicking a character shows these on the connected dots. |

When the Gallery opens in the editor, it checks every `Story/*/flow_graph.json`. Anyone who speaks in a story but isn't in this file (and isn't in `ignore_speakers`) gets a warning in the Output panel, so the web can't silently fall behind the story.

## Character modes

Every story scene runs the same `story_player.gd`. What makes each character feel different lives in a **mode** in `Scripts/StoryEngine/modes/`. A mode is a small script that extends `StoryMode` and fills in only what it needs:

| Function | What it decides |
|---|---|
| `info()` | Returns the mode's `INFO`: its meters, features, and the JSON keys and choice types it reads. |
| `setup()` / `get_meters()` / `set_meters()` | The character's meters. Rewinding and saving use these, so they work automatically. |
| `apply_choice(choice)` | What a choice does to the meters. |
| `is_locked(choice)` | Which choices are greyed out. |
| `choice_time(entry)` / `timeout_choice(choices)` | Timed choices, and what happens when time runs out. |
| `line_for(entry)` | What gets typed; return `"unsaid"` too for a self-edit. |
| `speed_multiplier()` / `apply_effects()` | Typing speed, screen tint, sounds. |

Every mode starts with an `INFO` that sums it up at a glance:

```gdscript
const INFO := {
	"meters": {
		"weight": "Emotional Weight, 0-100. LOW < 30, MEDIUM < 50, HIGH < 80, CRITICAL 80+.",
	},
	"features": [
		"Dimmed: the world fades to grey as weight rises.",
		"Slow text: typing slows down and the typing sound gets louder.",
		"Locked help: helpful choices lock at CRITICAL.",
	],
	"node_keys": [],
	"choice_keys": ["weight_change"],
	"choice_types": ["neutral", "honest", "helpful"],
}
```

When the game starts in the editor, it checks the story against this list. If a story uses a key, a choice type, or a meter that its mode doesn't know, the Output panel says so. This catches things like a `weight_change` left in Elysia's story, where it would silently do nothing.

**To make a new mode:** copy `elysia_mode.gd` (or `kay_mode.gd`), change `class_name`, rewrite `INFO` and the functions you need, and delete the rest; the base versions do nothing harmful. Put tunable numbers in `@export` variables so they can be changed in the Inspector.

Then add the same mode to `MODES` in TTFUI's `js/graph.js` (meters and their starting values, choice types, extra node keys, lock rule), so the editor can edit and playtest that character's story. If you change a mode's numbers in Godot (starting values, lock thresholds, timer), change them there too.

## Accessibility (screen readers and keyboard)

The game works with screen readers (NVDA on Windows, VoiceOver on macOS, Orca on Linux) through Godot's built-in accessibility (AccessKit). Sighted players see no difference.

The menu has a **Screen reader** option: *Auto* (default) turns the support on when a screen reader is found, *On* forces it, and *Off* turns it off. Godot doesn't always detect screen readers on Linux, so the game also asks the system (the AT-SPI bus, which knows when Orca is running). If it still isn't detected, set it to *On*.

> **Linux: use the official Godot download.** Distro packages such as Arch's `godot` are built without the AccessKit library, so Godot can't talk to Orca at all and nothing is read aloud. (When you run the game from the editor with a screen reader on, the Output panel warns about this.) The official build from [godotengine.org](https://godotengine.org/download/linux/) has it built in. Exported games use the official export templates, so players aren't affected.

**With a screen reader running:**
- Every line is announced as "Speaker: line", without the `*asterisks*`. Lines appear at once instead of being typed out.
- Things that only show on screen are described in words:
  - Elysia's self-edits: "Typed, then deleted: … Then: …"
  - Ulyn's cut-off thoughts: "… cut off. Then: …"
  - details to notice: "Something to notice: …. Press N to notice it."
  - locked and timed choices
  - incoming calls
- Choices and calls are read out with their numbers, and keyboard focus moves to the first one.
- Timed choices and calls last 3× longer (`screen_reader_timer_mult` on the story scene).
- Menus focus their first button when they open. Save slots, volume sliders and the character buttons ("K." is read as "Kay") have spoken names.
- The relationship web can be explored with the arrow keys. Each character is read out with all their connections.

**Keyboard shortcuts in a story (for everyone):**

| Key | Does |
|---|---|
| Space / Enter | Next line |
| Backspace | Previous line |
| 1 – 3 | Pick a choice (or answer / decline a call) |
| N | Notice a detail in the current line |
| A | Auto on / off |
| L | Log |
| Esc | Menu |

**Testing without a screen reader:** run the game with `-- --screen-reader`. In the editor, put `--screen-reader` in **Debug → Customize Run Instances → Main Run Args**. What would be read aloud is in each Control's `accessibility_name`. With **Debug Log** on, you can print it from `story_player.gd`.

**When you add UI:** give buttons that show only an icon or a letter an **Accessibility → Name** in the Inspector. Give anything that changes on its own (a popup, a counter) a **Live** mode so it gets announced. Use `Accessibility.focus()` instead of `grab_focus()` to focus something when it opens, so sighted players don't get a focus outline.

## Rules that keep things from breaking

- **Move or rename files inside Godot's FileSystem panel**, not in your file manager. Godot updates every reference for you; your file manager doesn't.
- **Commit the `.import` and `.uid` files** that sit next to assets and scripts. Godot needs them.
- **Close Godot before pulling** changes from GitHub, then reopen it. An open editor can save old settings over new ones.
- Turn on **Debug Log** on a story scene's root node to print the current node and the mode's meters while you play.
- Don't commit the `.godot/` folder (it's already ignored).
