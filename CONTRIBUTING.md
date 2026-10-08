# Helping with Untitled Illness

Thanks for helping! This page tells you where things are and how not to break them.

## Setup

1. Install **Godot 4.7** (the standard version, not .NET).
2. Clone the repo and open `project.godot` in Godot.
3. Press **F5** to play.

## Where things are

```
UntitledIllness/
├── Story/                    ✍️  Dialogue and branching, one folder per character
│   ├── README.md             How to write story nodes (start here if you're writing)
│   └── Kay/flow_graph.json
│
├── Scenes/                   🎬  Godot scenes, each next to its script
│   ├── Menus/                Splash screen, title menu, character select
│   ├── Dialog/               The dialogue box and choice buttons
│   └── Characters/           One story scene per character (backgrounds, sprites, sounds)
│
├── Scripts/StoryEngine/      ⚙️  The code that plays a story (shared by all characters)
│   ├── story_player.gd       Main script, attached to each character's story scene
│   ├── flow_graph.gd         Loads and checks the story JSON
│   ├── emotional_weight.gd   Emotional Weight value and LOW/MEDIUM/HIGH/CRITICAL
│   ├── typewriter.gd         Typing effect and sounds
│   ├── story_stage.gd        Backgrounds, characters, fades
│   └── story_audio.gd        Sound effect / ambience list
│
├── Assets/                   🎨  Art, audio, fonts, themes
│   ├── Photos/Background/    Backgrounds
│   ├── Photos/Sprites/       Character sprites
│   ├── Photos/UI/            Menu and side art
│   ├── audio/sfx/            Sound effects
│   ├── audio/amb/            Looping ambience
│   ├── audio/ui/             Typing sound
│   ├── Fonts/
│   └── Themes/               UI theme and dialogue box style
│
└── Docs/                     Project write-ups
```

## What do you want to do?

**Write or edit dialogue** → read [`Story/README.md`](Story/README.md), then edit the character's `flow_graph.json`. No code needed.

**Add a background**
1. Put the image in `Assets/Photos/Background/`.
2. Open the character's scene in `Scenes/Characters/`, add a `TextureRect` under **Bgs**, and set its texture.
3. The node's name is what you write in `"background"` in the story file.

**Add a character sprite / expression**
1. Put images in `Assets/Photos/Sprites/`.
2. In the character's scene, select the sprite under **Characters** and add animations to its SpriteFrames. The animation name is what you write in `"expression"`.

**Add a sound**
1. Put the file in `Assets/audio/sfx/` (or `amb/` for loops).
2. Add a line for it in `SFX` (or `AMB`) in `Scripts/StoryEngine/story_audio.gd`.

**Add a new character's story**
1. Make `Story/<Name>/flow_graph.json`.
2. Duplicate `Scenes/Characters/storykay1.tscn` and rename it.
3. Select the root node, and in the Inspector set **Flow Graph Path** to the new JSON. You can also set **Starting Weight** there.
4. Swap in that character's backgrounds and sprites.
5. Hook it up to the character select in `Scenes/Menus/selections.gd`.

## Rules that keep things from breaking

- **Move or rename files inside Godot's FileSystem panel**, not in your file manager. Godot updates every reference for you; your file manager doesn't.
- **Commit the `.import` and `.uid` files** that sit next to assets and scripts. Godot needs them.
- **Close Godot before pulling** changes from GitHub, then reopen it. An open editor can save old settings over new ones.
- Turn on **Debug Log** on a story scene's root node to print the current node and weight while you play.
- Don't commit the `.godot/` folder (it's already ignored).
