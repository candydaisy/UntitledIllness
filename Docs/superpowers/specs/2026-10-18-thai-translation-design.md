# Thai translation and Noto font

**Date:** 2026-10-18
**Why:** The teacher asked for a Thai version, chosen in Settings. The Minecraft font is also replaced with Noto everywhere.

## Goals

- A **Language** option in Settings: English / ไทย. It's saved in `user://settings.cfg` next to the volumes and the screen reader setting.
- **Everything** is translated: menus, buttons, minigame text, Debug page, screen reader lines, and all ~2,140 story lines in the Kay, Elysia and Ulyn routes.
- **One font family everywhere:** Noto Sans for Latin text, with Noto Sans Thai as its fallback for Thai. The Minecraft font is no longer used.
- English stays exactly as it is. Saves work in both languages.

## Not in scope

- Other languages. The system supports them, but only Thai is written.
- Translating the prose `*_Story.md` files and the docs. Those stay English; the game reads only the JSON.
- Voice lines or images with text in them.

## Font

- Copy `NotoSans-Regular.ttf`, `NotoSans-Bold.ttf`, `NotoSansThai-Regular.ttf`, `NotoSansThai-Bold.ttf` and the OFL license into `Assets/Fonts/`.
- `Assets/Fonts/noto.tres`: a `FontVariation` with Noto Sans as its base and Noto Sans Thai as its fallback. A bold version, `noto_bold.tres`, is made the same way.
- Every place that uses `Minecraft.ttf` switches to `noto.tres`. That's 5 themes (`default-theme`, `kay_theme`, `elysia_theme`, `ulyn_theme`, `theme1`), `dialog.tscn`, `title_menu.tscn` and `get_up.tscn`. It's also set as the project's default font (`gui/theme/custom_font`).
- Font sizes stay the same at first. They get checked by eye in the editor, because Noto is wider than Minecraft.

## Story text: one Thai file per route

`Story/<Route>/th.json` sits next to `flow_graph.json` and holds only translated strings, matched by node id:

```json
{
	"absent_3": {"text": "*เขารู้ว่าต้องลุก แต่ร่างกายไม่ขยับ*"},
	"seat_3":   {"text": "...", "choices": ["ไปนั่งกับเอลิเซีย", "อยู่ที่เดิม"]},
	"busy_4":   {"text": "...", "results": {"declined": "ตัดสาย", "let_ring": "ปล่อยให้มันดัง"}},
	"busy_4b":  {"text": "...", "cut_after": "...", "cut": "..."}
}
```

- Translatable keys: `text`, `real_text`, `cut`, `cut_after`, choice texts (a list, in the same order as the English choices) and result texts (keyed by result name).
- **A missing node or key falls back to English.** The game always runs, even when the translation is half done.
- `FlowGraph.load_from()` also loads the language file for the current locale, if there is one, and merges it over the English when a node is read. Everything else (secrets, flags, meters, saves) only ever sees node ids, so it doesn't change.
- Speaker names stay as they are (Kay, Elysia, Ulyn, Mom...). They're names, and the scenes find characters by them.

### Checker

This runs with the existing `_validate()` when a story starts from the editor. It warns when a `th.json` entry:

- names a node that isn't in `flow_graph.json`
- has a different number of choices than the English node
- names a result the node doesn't have
- loses or renames a `{detail|Flag}` link (the same flags must appear)
- has a `cut_after` that isn't the start of its Thai `text`

It also prints how many lines per route are translated, e.g. `th: Kay 312/974`.

## Interface text

- `Translations/ui.csv` has the columns `keys,en,th`. The English text is the key, so the scenes don't change. Godot imports it, and `project.godot` lists it under Localization.
- Godot translates `text` on Labels and Buttons by itself when the locale changes.
- Text set from scripts goes through `tr()`: minigame prompts, the Debug page, phone call text, screen reader lines, confirm dialogs ("Overwrite slot %d?"), and the log's Back button.

## Language setting

- `Settings` gets a "Language" row with an OptionButton (English / ไทย), built the same way as the Screen reader row.
- Choosing a language calls `TranslationServer.set_locale()` and saves it. On start, the saved locale is applied, defaulting to English.
- **Mid-story:** the menus change at once. The story reloads its Thai/English strings and redraws the current line in the new language, without moving to another node or changing meters.

## Thai and characters' voices

The translation is very casual, and the pronouns follow real relationships:

| Who | Pronouns / particles |
|---|---|
| Kay ↔ Ulyn, Elysia ↔ Mint, Ulyn ↔ Tan | กู / มึง |
| Kay ↔ Elysia | เค้า / ตัวเอง |
| Elysia's friend group (Ploy, Jane, Bow) | ชั้น / แก |
| To parents and teachers | ผม / หนู with ครับ / ค่ะ |
| Texts and chats | the way Thai teens type: short, no full stops, some English mixed in |

Things that keep their exact form in Thai: `{detail|Flag}` links, `*asterisks*` around narration, and emoji.

## Risks

- **Line breaking:** Thai has no spaces between words. Godot's advanced text server breaks Thai words using its ICU data. The **web export needs "Include Text Server Data"** ticked in the export preset, or Thai won't wrap.
- **Typewriter:** it reveals one character at a time, so a Thai vowel or tone mark could show for a frame before or after its letter. This gets checked in the game, and if it looks wrong, the typewriter steps over whole clusters (grapheme clusters).
- **Text length:** Thai lines can be longer or shorter than English. Choice buttons and the phone popup get checked for overflow.

## Order of work

1. Font switch to Noto (all themes and scenes).
2. Language setting, `ui.csv`, `tr()` in scripts.
3. `th.json` loading, fallback, checker, mid-story switching.
4. Translation, one route at a time: Kay → Elysia → Ulyn. Claude drafts each route; the user (a native speaker) reviews it, and the user's fixes win.

Each step is tested headless the same way the minigames were, and the user checks it by eye in Godot.
