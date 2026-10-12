# Writing the story

Each character's story is one JSON file in this folder. Next to it is the same story written as prose (`*_Story.md`), which is easier to read and review:

```
Story/
├── Canon_Timeline.md      what actually happens, across every route
├── Characters/            who each character is
├── Kay/flow_graph.json    + Kay_Story.md
├── Ulyn/flow_graph.json   + Ulyn_Story.md
└── Elysia/flow_graph.json + Elysia_Story.md
```

Ulyn's and Elysia's routes don't have backgrounds, characters or sounds yet. Ulyn doesn't have a story scene or a mode yet. His endings are currently tuned for Kay's weight system starting at 50.

You don't need to touch any code to write or change dialogue. Edit the JSON, save, and run the game in Godot.

## How a story works

A story is a list of **nodes**. Each node is one line of dialogue and has an id. The game starts at the node set as **Start Node** on the story scene (Kay's is `"start"`) and follows `next` from node to node.

Ids can be any text. Name them after the scene they're in, like `gate_3` or `lunch_stay_2`, so you can tell where you are in the file. To add a line between `gate_3` and `gate_4`, give it a new id like `gate_3b` and update `gate_3`'s `next`. You don't need to renumber anything.

```json
"wake_3": {
	"speaker": "Kay",
	"emotion": "tired",
	"text": "Monday...",
	"next": "wake_4",
	"background": "Kay's room1"
},
```

A node with no `next` and no `choices` ends the story.

## Everything a node can have

| Key | What it does | Example |
|---|---|---|
| `speaker` | Name on the name plate. `""` for narration. | `"Kay"` |
| `text` | The line itself. | `"I should get ready for school."` |
| `next` | The node that comes after this one. | `"4"` |
| `emotion` | Changes typing speed: `angry` (fast), `nervous`, `tired`, `sad` (slow). | `"tired"` |
| `background` | Switches background. Must match a node name under **Bgs** in the character's scene. | `"Gate"` |
| `show_characters` | Fades characters in. Names must match nodes under **Characters**. | `["Kay", "Ulyn"]` |
| `hide_characters` | Fades characters out. | `["Elysia"]` |
| `expression` | Plays a sprite animation on a character. | `{"Kay": "School"}` |
| `sfx` | Plays a sound effect, or `"stop"` to fade it out. | `"Alarm"` |
| `amb` | Starts a looping background sound, or `"stop"`. | `"Bedroom"` |
| `voice` | Plays a voice line. It stops when the dialog moves to the next line. | `"kay_wake_3"` |
| `choices` | Shows up to 3 choice buttons (see below). Use instead of `next`. | |
| `secret` | Jumps to a different node if a condition is true (see below). | |

Available sound and voice names are listed in `Scripts/StoryEngine/story_audio.gd`. If you need a new one, ask whoever's handling code, or add it there yourself.

## Choices

```json
"9": {
	"speaker": "Kay",
	"text": "What should I do first?",
	"choices": [
		{ "text": "Take a shower",       "type": "neutral", "weight_change": 0,  "next": "10" },
		{ "text": "Tell Ulyn the truth", "type": "honest",  "weight_change": -5, "next": "40", "set_flag": "ToldUlyn" },
		{ "text": "Offer to help",       "type": "helpful", "weight_change": 5,  "next": "41" }
	]
},
```

- `weight_change` adds to the character's **Emotional Weight** (0–100). Positive = more pressure, negative = relief.
- `type`: `neutral`, `honest`, or `helpful`. **`helpful` choices get locked (greyed out) when weight is CRITICAL.**
- `set_flag` (optional) remembers that this choice was picked, for use in a `secret` later.

Weight states: **LOW** under 30, **MEDIUM** under 50, **HIGH** under 80, **CRITICAL** 80+. Higher weight makes the screen greyer and the text slower.

## Secrets (hidden branches)

A secret sends the player somewhere else *after* this node, if a condition is met. Otherwise `next` is used as usual.

```json
"104": {
	"speaker": "Kay",
	"text": "...",
	"next": "105",
	"secret": { "condition": "flag_true", "flag": "Girlfriend", "next": "108" }
},
```

| `condition` | Needs | True when |
|---|---|---|
| `flag_true` | `flag` | that flag was set by a choice |
| `flag_false` | `flag` | that flag was never set |
| `weight_above` | `value` | weight is above the value (Kay) |
| `weight_below` | `value` | weight is below the value (Kay) |
| `mask_above`, `mask_below`, `energy_above`, `energy_below` | `value` | the same, for Elysia's meters |

## Each character plays differently

Every story scene uses the same StoryPlayer, plus a **Mode** (set on the scene's root node in the Inspector). The mode decides the character's meters, what choices do to them, and how the game reacts. You can tune a mode's numbers in the Inspector too.

| Scene | Mode | Meters |
|---|---|---|
| `Scenes/Characters/Story.tscn` | KayMode (the default when Mode is empty) | `weight` |
| `Scenes/Characters/Elysia.tscn` | ElysiaMode | `mask`, `energy` (both hidden) |

**Kay** uses everything above: `weight_change` on choices, the screen greys out as weight rises, and `helpful` choices lock at CRITICAL.

**Elysia** performs a "version" of herself, so her route works differently:

| Key | Where | What it does | Example |
|---|---|---|---|
| `mask_change` | choice | How much the choice adds to her performing. Use instead of `weight_change`. | `10` |
| `energy_change` | choice | What it costs (−) or gives back (+). | `-15` |
| `type: "perform"` | choice | The "version" answer. Picked automatically if a timed choice runs out. | |
| `timed` | node with choices | Gives the player a few seconds (8 at Mask 0, 4 at Mask 100). | `true` |
| `real_text` | node | What she really wants to say. While Mask is 60+, it's typed, deleted, and replaced by `text`. Below 60 she just says it. | `"\"I'm just tired, Mom.\""` |

Her `honest` choices lock when Energy is below 20 or Mask is above 85.

Secrets can test any meter the mode has: `weight_above`, `mask_below`, `energy_above`, and so on.

## Checking your work

Run the game from the Godot editor. On start it checks the whole story file and prints a **warning in the Output panel** for anything that doesn't line up: a `next` pointing to a missing node, a background or character name that isn't in the scene, an unknown sound, etc.

Common mistakes:
- Ids are always in quotes: `"next": "gate_4"`.
- Names are case-sensitive: `"useless1"` is not `"Useless1"`.
- Every node except the last needs a comma after its closing `}`.
