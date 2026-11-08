# Character sprite prompts

Gemini prompts for every character the story puts on screen.

**Style:** graphite pencil sketch, waist-up. Everything is grey pencil except
the irises, which are the character's one color. School uniform: white
long-sleeve shirt, dark trousers or a dark skirt.

## How to use

1. **Neutral first.** For each character, paste the **Style** block, then the
   character's **Look** block. Generate until the face and design feel right.
2. **Then the expressions** (Kay, Elysia, Ulyn). In the same chat, or a new one
   with the neutral image attached, paste the **Expression** block with the
   line for that expression. Attaching the neutral keeps the face, hair,
   clothes, pose and size identical, so the sprites swap without jumping.
3. **Save** as `Assets/Sprites/<Character>/<expression>.png`, for example
   `Assets/Sprites/Kay/neutral.png`.
4. **Remove the white background** outside the figure (remove.bg, Photopea's
   magic wand, or ask me to do it with a script). Keep the white *inside* the
   outline: that paper-white fill is what keeps the pencil readable on the
   dark night backgrounds.

If a result comes out colored, too clean or too detailed, reply in the same
chat: *"Only graphite pencil, rougher sketch lines, no color except the
irises, plain white background."*

---

## Style block (paste first, every time)

> Character sprite for a visual novel. Hand-drawn graphite pencil sketch on white paper: soft, slightly rough sketch lines, light cross-hatching and smudged shading, visible pencil grain. The whole drawing is black-and-white graphite, except the irises of the eyes, which are softly colored. Waist-up, standing, front three-quarter view turned slightly to the viewer's left, centered, head near the top with a little space above it, cut off at the waist at the bottom edge. The figure has a clear closed outline and is filled with paper-white and soft grey shading, never see-through. Plain pure white background with nothing on it. Portrait, 2:3. Avoid: any color except the irises, background scenery, ground shadow, frames, borders, text, signature, watermark, more than one person, extra fingers.

## Expression block (for the extra expressions)

> Using the attached sprite as the exact reference: same character, same drawing style and line quality, same face, hair, clothes, pose, framing and size, same plain white background, same graphite-only look with only the irises in color. Change only the facial expression and a small detail of posture, as described: [EXPRESSION LINE]

---

## Kay — eyes: grey-blue

**Look**
> A 17-year-old boy, thin, neat but tired. Tidy short dark hair, carefully combed. Neat white long-sleeve school shirt, buttoned properly, sleeves down; dark trousers. A polite, practiced small smile that doesn't quite reach his eyes; faint dark circles under the eyes that he hides well. Irises grey-blue.

| File | Expression line |
|---|---|
| `Kay/neutral.png` | *(the Look prompt above)* |
| `Kay/smile.png` | A real, small smile this time: the eyes soften and crinkle slightly, shoulders relaxed. |
| `Kay/sad.png` | The smile is gone. Eyes lowered, mouth flat, shoulders dropped a little. |
| `Kay/tired.png` | Heavy eyelids, darker circles under the eyes, a strand of hair out of place, head tilted slightly down. |
| `Kay/nervous.png` | A forced polite smile, eyebrows tense, eyes glancing aside, one thumb pressed hard into the other palm in front of him. |
| `Kay/teasing.png` | A dry, sly half-smile, one eyebrow slightly raised, eyes amused. |

## Elysia — eyes: amber-yellow

**Look**
> A 17-year-old girl, sporty and bright. Long hair in a high ponytail, a few loose strands by her face. White long-sleeve school shirt with the sleeves rolled up to the elbows; dark pleated skirt (only the waistband visible). Open, bright, friendly smile, energetic posture. Irises amber-yellow.

| File | Expression line |
|---|---|
| `Elysia/neutral.png` | *(the Look prompt above)* |
| `Elysia/happy.png` | Laughing for real, eyes squeezed nearly shut, head tipped back a little. |
| `Elysia/sad.png` | The smile has fallen. Eyes glassy and looking down, lips pressed together. |
| `Elysia/tired.png` | Still smiling, but the eyes are drained and unfocused; ponytail looser, strands falling out. |
| `Elysia/nervous.png` | A tight, careful smile, eyes glancing sideways as if checking who's watching, one hand fiddling with the end of her ponytail. |
| `Elysia/flustered.png` | Embarrassed and annoyed at once: cheeks shaded darker, mouth open mid-protest, eyebrows up, pointing a finger. |

## Ulyn — eyes: deep red-brown

**Look**
> A 17-year-old boy, sharp and put-together. Short, clean haircut. Straight posture. White long-sleeve school shirt, crisp and tucked in, sleeves buttoned; dark trousers. A confident, teasing half-smile; the only crack is in his eyes, which look a little tired. Irises deep red-brown.

| File | Expression line |
|---|---|
| `Ulyn/neutral.png` | *(the Look prompt above)* |
| `Ulyn/grin.png` | A wide, easy grin, eyes bright, chin slightly up. |
| `Ulyn/sad.png` | The half-smile is gone. Eyes red-rimmed and lowered, jaw tight, shoulders slightly hunched. |
| `Ulyn/tired.png` | Still upright, but with heavy eyelids, a crease on his forehead and a faint slump in the shoulders. |
| `Ulyn/angry.png` | Frustrated: brows drawn down, mouth set hard, looking straight at the viewer, arms crossed. |
| `Ulyn/worried.png` | Searching look, brows pulled together, lips slightly parted as if about to ask something, leaning a little forward. |

---

## Supporting cast (neutral only)

Paste the **Style** block, then the character's line. Save as `<Name>/neutral.png`.

| File | Eyes | Look |
|---|---|---|
| `Mom/neutral.png` (Kay's mom) | grey-blue | A woman in her early forties, tired but warm. Hair tied back in a quick low ponytail, a few loose strands. Plain hospital nurse scrub top with a cardigan over it. Gentle, slightly apologetic smile, faint lines under the eyes. Irises grey-blue. |
| `ElysiaMom/neutral.png` (Elysia's mom) | amber-yellow | A woman in her forties, busy and kind. Shoulder-length hair clipped up loosely, an apron over a simple blouse, holding a ladle. Big warm smile, quick lively eyes. Irises amber-yellow. |
| `UlynMom/neutral.png` (Ulyn's mom) | deep red-brown | A woman in her forties, careful and lonely. Neat shoulder-length hair, a soft knit cardigan buttoned up, hands held together in front of her. A hopeful, nervous smile. Irises deep red-brown. |
| `Pun/neutral.png` | amber-yellow | An 8-year-old boy, Elysia's little brother, serious and curious. Messy short hair, an oversized T-shirt, holding a small glass jar with a twig inside close to his chest. Solemn, studying expression. Irises amber-yellow. |
| `Bank/neutral.png` | dark brown | A 17-year-old boy, easygoing and a little lazy. Messy hair, school shirt untucked on one side, sleeves pushed up, a phone in his hand. Sheepish, friendly grin. Irises dark brown. |
| `Fern/neutral.png` | hazel | A 17-year-old girl, bubbly and eager. Long straight hair with a headband, neat uniform, holding a phone up as if about to take a photo. Big bright smile. Irises hazel. |
| `Ploy/neutral.png` | brown | A 17-year-old girl, dramatic and social. Long wavy styled hair, uniform worn a little stylishly, phone in hand mid-text. Expressive face, eyebrows raised as if telling gossip. Irises brown. |
| `Mint/neutral.png` | dark green | A 17-year-old girl, short and blunt. Short blunt bob with straight bangs, uniform neat, arms crossed, holding a carton of chocolate milk. Deadpan, unsmiling face. Irises dark green. |
| `MsNoi/neutral.png` | warm brown | A teacher in her fifties, calm and kind. Hair in a low bun with some grey, glasses pushed up on her head, a cardigan over a blouse, holding a cup of tea. Patient, quiet smile. Irises warm brown. |
| `Tan/neutral.png` | deep red-brown | A college student around 20, Ulyn's cousin, relaxed and dry. Messy hair, loose T-shirt, a mug of instant noodles in one hand. Sleepy, knowing half-smile. Irises deep red-brown. |
| `Pim/neutral.png` | grey | A 17-year-old girl, student council president, stressed but capable. Hair clipped back neatly, uniform perfect, a clipboard hugged to her chest, a pen behind her ear. Tight, overworked smile. Irises grey. |
| `Jane/neutral.png` | light brown | A 17-year-old girl, quiet follower in Ploy's group. Long straight hair tucked behind her ears, neat uniform. Polite, slightly unsure smile. Irises light brown. |
| `Bow/neutral.png` | blue-grey | A 17-year-old girl, cheerful and undecided. Hair in two low braids, uniform with a cardigan tied around her shoulders. Friendly, uncertain smile. Irises blue-grey. |
| `Nam/neutral.png` | soft green | A 17-year-old girl, shy art-class student. Short tousled hair, a school bag strap over her shoulder with a small plush frog keychain hanging from it, holding a sketchbook. Wary, quiet expression. Irises soft green. |

### About the moms

The game has one "mom" sprite slot per route scene, so each route can show
its own mom. Kay's route uses `Mom/`, Elysia's uses `ElysiaMom/`, Ulyn's uses
`UlynMom/`. Elysia's mom also appears briefly in Kay's route (family dinner).

---

## Optional: outfit variants

The story already asks for a few: `{"Kay": "School"}` and `{"Elysia": "friends"}` / `"default"`.
If you want weekend clothes (the museum Saturday, the hoodie scenes), use the
Expression block with:

- `Kay/casual.png`: *Same face and neutral expression, but in a plain dark hoodie over a T-shirt instead of the uniform.*
- `Elysia/casual.png`: *Same face and neutral expression, but in a loose T-shirt and a light jacket, ponytail lower.*
- `Elysia/hoodie.png`: *Same face, a shy happy smile, wearing a plain dark hoodie that is too big for her, sleeves past her hands.*
