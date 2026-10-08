# Untitled Illness

> *People can look fine on the outside and still be carrying something heavy.*

**Untitled Illness** is a narrative-driven visual novel about the emotional lives of high school students. It explores how someone can seem cheerful, calm, or completely in control while dealing with struggles that nobody else can see.

You play through the perspectives of different students in the same school. The same ordinary moments (a class, a chat with a friend, an evening alone) can mean something very different depending on whose eyes you're seeing them through.

There is no winning or losing. Your choices shape how characters respond to their situations and how their emotional state shows up in the game.

---

## Features

- **Multiple perspectives.** Each route follows a different student and a different way of coping: suppressing feelings, staying busy to avoid them, regret, isolation, or struggling to communicate.
- **Emotional Weight system.** There's no health bar or morality meter. Instead, an internal *Emotional Weight* tracks how much pressure a character is carrying.
- **Presentation that reacts to how the character feels.** As pressure builds, colours desaturate, text slows down, choices disappear, and the world gets quieter.
- **Quiet, realistic storytelling.** Classrooms, school entrances, cafeterias, and bedrooms. The struggles happen in ordinary daily life, not in big dramatic events.

## Emotional Weight

| State | What changes |
|---|---|
| **Low** | The character is fairly stable, with a normal range of dialogue choices. |
| **Medium** | The character starts to feel overwhelmed. The presentation and available choices begin to shift. |
| **High** | The character has much less emotional capacity: slower text, fewer choices, a quieter atmosphere. |
| **Critical** | Some responses and interactions are no longer available, showing how pressure affects a person's ability to communicate. |

Supportive interactions can bring some temporary stability. Stressful situations and bottling things up add to the weight.

> The Emotional Weight system is a storytelling device. It does **not** measure or represent real mental health.

## Characters

**Kay** is the student everyone goes to for advice. He seems calm, reliable, and put-together. Inside, he overthinks constantly and lives with difficult thoughts he never shares. His story is about wanting to be there for others while being afraid that talking about his own problems would make him a burden.

*More routes and characters are in development.*

## Why this game?

The core idea behind *Untitled Illness* is **perspective-taking**. Most stories let you watch a character's problems from the outside. This one puts you inside their head, so you get information that the other characters in the story don't have.

- A quiet student might not be uninterested in their surroundings.
- Someone who always helps others might be struggling to ask for help themselves.
- Someone who says "I'm fine" might be trying to convince themselves.

The game doesn't tell you what to think. It asks you to notice, and to reconsider how you read other people.

**Objectives**

1. Let players experience school life from several students' points of view.
2. Show that emotional struggles aren't always visible in someone's behaviour.
3. Show how everyday conversations and decisions can affect another person.
4. Encourage reflection on communication, support, and relationships between students.
5. Explore games as an interactive medium for social and emotional topics.

## Who it's for

Mainly high school and university-age players, especially those who enjoy visual novels, narrative games, and psychological storytelling. The themes aren't limited to students, though. Anyone who has dealt with academic pressure, difficult relationships, holding emotions in, or not knowing how to reach out may see themselves in parts of the story.

## Built with

- [Godot Engine 4.7](https://godotengine.org/) (GL Compatibility renderer)
- Export targets: **Web** (itch.io) and **Android**

## Running the project

1. Install **Godot 4.7**.
2. Clone this repository:
   ```bash
   git clone https://github.com/candydaisy/UntitledIllness.git
   ```
3. Open Godot, choose **Import**, and select `project.godot`.
4. Press **F5** to run.

## Project structure

```
UntitledIllness/
├── Story/              # Dialogue and branching, one folder per character
├── Scenes/             # Menus, dialogue box, and each character's story scene
├── Scripts/StoryEngine # Shared code that plays a story
├── Assets/             # Art, audio, fonts, themes
└── Docs/               # Project write-ups
```

Want to help? See [CONTRIBUTING.md](CONTRIBUTING.md). Writing dialogue? See [Story/README.md](Story/README.md).

## A note on the subject matter

*Untitled Illness* is an educational, awareness-focused project. It is **not** meant to diagnose any condition or replace professional help. It deals with emotional distress, so please play at your own pace.

If you're struggling, please talk to someone you trust or reach out to a local mental health helpline.
