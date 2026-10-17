# Thai Translation and Noto Font Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Minecraft font with Noto everywhere, and add an English / ไทย language setting that translates every menu, minigame and story line.

**Architecture:** Interface text uses Godot's built-in CSV translation (`tr()`, auto-translated Controls). Story text lives in one `th.json` per route, merged over the English nodes inside `FlowGraph` when the locale is Thai, so the rest of the engine keeps reading `graph.nodes` unchanged. A checker in `_validate()` guards links, cut-offs and choice counts.

**Tech Stack:** Godot 4.7 (GDScript), JSON story files, CSV translations, Noto Sans + Noto Sans Thai (OFL).

**Spec:** `Docs/superpowers/specs/2026-10-18-thai-translation-design.md`

## Global Constraints

- Godot 4.7.2; test with `godot --headless --path . -s res://Tests/<test>.gd`. A test prints `PASS` and calls `quit(0)`, or prints `FAIL: <reason>` and calls `quit(1)`.
- English text and `flow_graph.json` files must not change (except `Story/README.md` docs).
- Locale codes: `"en"` and `"th"`. Default `"en"`. Saved in `user://settings.cfg`, section `"general"`, key `"locale"`.
- Font: `Assets/Fonts/noto.tres` (FontVariation, base `NotoSans-Regular.ttf`, fallback `NotoSansThai-Regular.ttf`). The Minecraft font is no longer referenced anywhere. Bold is dropped from the spec: nothing in the game renders bold.
- Story translation file: `Story/<Route>/th.json`. Translatable keys only: `text`, `real_text`, `cut`, `cut_after`, `choices` (list of strings, same order as English), `results` (`{result_name: text}`). Missing node or key = English.
- Speaker names stay English.
- Thai voice: the pronoun table in the spec (กู/มึง for close friends, เค้า/ตัวเอง for Kay–Elysia, ชั้น/แก for Elysia's friend group, ผม/หนู + ครับ/ค่ะ to adults). `{detail|Flag}` links, `*asterisks*` and emoji are kept as they are.
- Every commit ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Switching language while a choice or a phone call is showing:** the buttons should change language too, and the timer shouldn't restart. Pinned in Task 4.
2. **A `requires` choice hidden by `filter_choices`:** the Thai choice list is indexed by the English list *before* filtering, so the remaining buttons still show the right Thai. Pinned in Task 3.
3. **Loading an English save while Thai is selected** (and the reverse): the line shows in the current language, and the log keeps old lines in the language they were played in. Pinned in Task 4.
4. **Thai vowels and tone marks during typing:** a mark must never appear on its own for a frame. Pinned in Task 5.
5. **A broken `th.json` (bad JSON):** the game logs an error and plays in English, and doesn't crash. Pinned in Task 3.

---

### Task 1: Noto font everywhere

**Files:**
- Create: `Assets/Fonts/NotoSans-Regular.ttf`, `Assets/Fonts/NotoSansThai-Regular.ttf`, `Assets/Fonts/OFL.txt` (copied from `/usr/share/fonts/noto/` and `/usr/share/licenses/noto-fonts/LICENSE`)
- Create: `Assets/Fonts/noto.tres`
- Modify: `Assets/Themes/{default-theme,kay_theme,elysia_theme,ulyn_theme,theme1}.tres`, `Scenes/Dialog/dialog.tscn`, `Scenes/Menus/title_menu.tscn`, `Scenes/Minigames/get_up.tscn`, `project.godot`
- Test: `Tests/test_font.gd`

**Interfaces:**
- Produces: `res://Assets/Fonts/noto.tres`, which every theme and scene uses.

- [ ] **Step 1: Write the failing test** `Tests/test_font.gd`: load `noto.tres` and assert that `has_char(ord("A"))` and `has_char(ord("ก"))` are both true (Thai through the fallback). Then scan every `.tres`/`.tscn` under `res://Assets` and `res://Scenes` and FAIL if any contains `Minecraft.ttf`.
- [ ] **Step 2: Run it.** `godot --headless --path . -s res://Tests/test_font.gd` → FAIL (`noto.tres` missing).
- [ ] **Step 3: Implement.** Copy the font files. Write `noto.tres` as a `FontVariation` with `base_font` set to Noto Sans and `fallbacks = [NotoSansThai]`. Replace every `Minecraft.ttf` ext_resource path with `res://Assets/Fonts/noto.tres` (type `FontVariation`; keep each file's resource id). Set `gui/theme/custom_font="res://Assets/Fonts/noto.tres"` in `project.godot`. Run `godot --headless --path . --import` once so the fonts import.
- [ ] **Step 4: Run the test** → PASS. Also load `Kay.tscn` headless (`--quit-after 60`) and confirm there are no new errors.
- [ ] **Step 5: Commit** "Switch all text to Noto Sans with Noto Sans Thai fallback". Ask the user to check font sizes by eye in Godot before moving on.

### Task 2: Language setting and interface translation

**Files:**
- Create: `Translations/ui.csv`
- Modify: `Scenes/Menus/setting.gd`, `project.godot`, every script that sets visible text: `Scenes/Minigames/{get_up,slime_maze,ninety_unread}.gd`, `Scripts/StoryEngine/{story_player,dialog_log,phone_popup,accessibility}.gd`, `Scenes/Menus/*.gd`
- Test: `Tests/test_language.gd`

**Interfaces:**
- Produces: `SettingMenu.LOCALES := ["en", "th"]`, `static func SettingMenu.apply_saved_locale() -> void`, `static func SettingMenu.set_locale(locale: String) -> void` (sets the locale on TranslationServer and saves it).

- [ ] **Step 1: Write the failing test** `Tests/test_language.gd`: call `SettingMenu.set_locale("th")`, then assert `tr("Settings") == "ตั้งค่า"`, `tr("Back") == "กลับ"`, and that `ConfigFile` at `user://settings.cfg` has `general/locale == "th"`. Set it back to `"en"` and assert `tr("Settings") == "Settings"`.
- [ ] **Step 2: Run it** → FAIL (no `set_locale`).
- [ ] **Step 3: Collect the strings.** List every visible English string: `text = "..."` in `.tscn` files under `Scenes/`, and string literals passed to `.text =`, `Accessibility.say(...)`, `_ask(...)` and `prompt.text` in `.gd` files. Write `Translations/ui.csv` with the header `keys,en,th` and one row per string. Thai goes in the `th` column; format strings keep their `%d`/`%s`. Register `res://Translations/ui.en.translation` and `ui.th.translation` under `internationalization/locale/translations` in `project.godot`, and set `internationalization/locale/include_text_server_data=true` (needed for Thai line breaking on the web).
- [ ] **Step 4: Implement** `set_locale` and `apply_saved_locale` in `setting.gd`. Call `apply_saved_locale()` at the top of `SettingMenu._ready()`. Add a "Language" row under the Screen reader row, built the same way, with items "English" and "ไทย". Wrap every script-set string from Step 3 in `tr()`, formatting after translating: `tr("Overwrite slot %d?") % slot`.
- [ ] **Step 5: Run the test** → PASS. Commit "Add language setting and translate the interface".

### Task 3: Thai story files load into FlowGraph

**Files:**
- Modify: `Scripts/StoryEngine/flow_graph.gd`
- Create: `Story/Kay/th.json` (a few nodes only, as a fixture; filled in Task 6)
- Test: `Tests/test_story_language.gd`

**Interfaces:**
- Consumes: the locale from `TranslationServer.get_locale()`.
- Produces: `FlowGraph.source : Dictionary` (the English nodes, never changed), `FlowGraph.nodes` (English merged with the translation; every existing reader keeps working), `func FlowGraph.apply_language(locale: String) -> void`, `func FlowGraph.translated_count() -> Vector2i` (translated, total nodes with text).

- [ ] **Step 1: Write the failing test.** Build a FlowGraph with `source` = three nodes: plain text; one with 3 choices where the 2nd has `"requires"`; one minigame node with `results`. Write a matching temporary `th.json` to `user://`, then call `apply_language("th")` on it. Assert:
  - the translated `text` and `choices[i]["text"]` come back
  - English is kept for the node with no Thai entry
  - result texts are translated
  - `next`, `set_flag` and `weight_change` are untouched
  - `apply_language("en")` restores the English
  - a `th.json` with invalid JSON leaves the English and doesn't crash
- [ ] **Step 2: Run it** → FAIL.
- [ ] **Step 3: Implement.** `load_from(path)` keeps the English in `source`, then calls `apply_language(TranslationServer.get_locale())`. `apply_language` deep-duplicates `source` into `nodes`. For a locale other than `"en"`, it reads `<dir of path>/<locale>.json` if the file exists, and overwrites only the translatable keys listed in Global Constraints. Choice texts are matched by index into the unfiltered list. A parse error gives `push_error` and English. Store the path so `apply_language` can find the file.
- [ ] **Step 4: Run the test** → PASS. Run `test_minigame`-style headless play of `Kay.tscn` from `absent_1` and confirm it still reaches `absent_2`.
- [ ] **Step 5: Commit** "Load per-route Thai story files over the English".

### Task 4: Live language switching and the translation checker

**Files:**
- Modify: `Scripts/StoryEngine/story_player.gd`
- Test: `Tests/test_story_switch.gd`

**Interfaces:**
- Consumes: `FlowGraph.apply_language`, `FlowGraph.source`, `FlowGraph.translated_count`.
- Produces: `func StoryPlayer._relocalize() -> void`, called from `_notification(NOTIFICATION_TRANSLATION_CHANGED)`.

- [ ] **Step 1: Write the failing test.**
  - Load `Kay.tscn` at a node with choices. Wait until the choices show, then switch to `th`. Assert:
    - the visible choice buttons show the Thai text from the fixture
    - `current_node` and the meters are unchanged
    - the choice timer (if any) wasn't reset
    - the log has no duplicate line
  - Repeat with a `call` node (Ulyn `seven_1`) and check the phone buttons.
  - Load a save made in English while `th` is selected: the current line is Thai, and older log lines stay as they were.
- [ ] **Step 2: Run it** → FAIL.
- [ ] **Step 3: Implement `_relocalize()`.**
  - Call `graph.apply_language(TranslationServer.get_locale())`, then redraw the current line without `process_node`: no stage, sound or history changes.
  - Replace the last log entry with the redrawn line.
  - Rewrite the texts of the visible choice buttons and the phone buttons from the freshly filtered choices.
- [ ] **Step 4: Add the checker to `_validate()`.** For each node in the loaded translation:
  - it exists in `source`
  - the choice list length matches
  - every result key exists
  - the set of `{…|Flag}` flags in `text` equals the English set
  - `cut_after` is a prefix of the Thai `text`

  Push a warning naming the node and the problem. Print `th: <Route> <translated>/<total>`.
- [ ] **Step 5: Run the test** → PASS, and loading `Kay.tscn` prints the progress line. Commit "Switch story language live and check Thai lines".

### Task 5: Typewriter keeps Thai marks with their letter

**Files:**
- Modify: `Scripts/StoryEngine/typewriter.gd` (every place that changes `label.visible_characters`)
- Test: `Tests/test_typewriter_thai.gd`

**Interfaces:**
- Produces: `static func Typewriter.is_combining(ch: String) -> bool` (true for U+0E31, U+0E34–U+0E3A, U+0E47–U+0E4E).

- [ ] **Step 1: Write the failing test.** Type `"น้ำ ที่นี่"` on a RichTextLabel with a slow speed, stepping one frame at a time. At every frame, assert that the character just after `visible_characters` is not a combining mark, i.e. no tone or vowel mark is cut off from its letter.
- [ ] **Step 2: Run it** → FAIL.
- [ ] **Step 3: Implement.** Wherever `visible_characters` goes up, keep stepping forward while the next character `is_combining`. Wherever it goes down (self-edit deleting), keep stepping back while the character at the new end `is_combining`.
- [ ] **Step 4: Run the test** → PASS. Commit "Typewriter reveals Thai letters with their marks".

### Task 6: Translate Kay's route

**Files:**
- Modify: `Story/Kay/th.json` (complete)
- Test: `Tests/test_translation_complete.gd` (route name as a user arg)

- [ ] **Step 1: Write the test.** For the route given in `OS.get_cmdline_user_args()`, load `flow_graph.json` and `th.json`. FAIL if any node with `text` lacks a Thai `text`, if any node with choices lacks a full `choices` list, or if the checker rules from Task 4 fail. Print the count.
- [ ] **Step 2: Run it:** `godot --headless --path . -s res://Tests/test_translation_complete.gd -- Kay` → FAIL with the missing count.
- [ ] **Step 3: Translate** all 974 strings in batches of about 150 nodes in story order, following the voice rules in Global Constraints. Keep `{detail|Flag}`, `*…*`, emoji and `cut_after` prefixes exact. After each batch, run the test to see the count drop.
- [ ] **Step 4: Run the test** → PASS. Play `absent_1` in Thai headless and confirm the minigame result texts are Thai.
- [ ] **Step 5: Commit** "Translate Kay's route to Thai". Hand it to the user to review; their corrections are applied as follow-up commits.

### Task 7: Translate Elysia's route

Same as Task 6 with `-- Elysia` (549 strings), file `Story/Elysia/th.json`. Watch for `real_text` (self-edit): it must read as the "real" version of the Thai `text`. Commit "Translate Elysia's route to Thai".

### Task 8: Translate Ulyn's route

Same as Task 6 with `-- Ulyn` (618 strings), file `Story/Ulyn/th.json`. Watch for `cut_after`, which must be the start of the Thai `text` (the checker enforces it). Commit "Translate Ulyn's route to Thai".

### Task 9: Docs and final pass

**Files:**
- Modify: `Story/README.md` (a "Translations" section: the `th.json` format, the fallback, the checker, and how to add a language), `CONTRIBUTING.md` (one line pointing to it)

- [ ] **Step 1:** Write the README section, with one example entry for each translatable key.
- [ ] **Step 2:** Run every test in `Tests/` and load all three story scenes headless in `th`. Expect no warnings beyond the existing missing-sprite ones. Then ask the user to check by eye, in Thai, that choice buttons, the phone popup and minigame prompts don't overflow. Shorten any Thai line that does.
- [ ] **Step 3:** Commit "Document translations". Remind the user: tick nothing extra in the export preset (text server data is set in Project Settings), and re-export.
