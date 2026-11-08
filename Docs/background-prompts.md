# Background prompts

Scenes whose background doesn't match the story, with a Gemini prompt for each.

## How to use

1. In Gemini, attach the **reference image** listed for the scene (from
   `Assets/Photos/Background/`). It sets the camera, light, color and blur.
2. Paste the **prompt**. Every prompt has the same opening and the same
   "Avoid" list, so all the new images match the old ones.
3. Save the result as `Assets/Photos/Background/<file name>`.

If an image still comes out too sharp or busy, reply in the same chat:
*"Simpler. Fewer objects, more empty floor, softer blur, darker, flatter light."*

What the current backgrounds have in common (and what the prompts ask for):
a tidy, generic modern school or suburban home; almost empty; eye level, wide
shot with open floor in the front for the characters; overcast, flat, dim
light; cool grey with a little warm brown; deep soft shadows; a gentle blur
over the whole frame like a half-remembered photo.

"Scene name" is the name the story JSON uses (`"background": "..."`). Names
marked **new** need adding to `Scenes/Characters/<Route>.tscn` too.

---

## School

### 1. Garden — `SchoolGarden_blur.png`
Reference: `FrontLawn_blury.png`. Now shows the front lawn. Used 15× (Kay 11, Elysia 1, Ulyn 3).
> Match the attached image exactly in style: same camera height, same overcast flat light, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: a small, tidy school garden behind a plain modern school building. Four simple raised wooden beds with small young seedlings in dark soil, a garden hose neatly coiled by an outdoor tap on the wall, short trimmed grass, open empty ground in the foreground. Avoid: people, text, clutter, weeds, moss, stains, rot, dirt on walls, bright or saturated colors, sharp detail, high contrast.

### 2. Sports field — `SportsField_blur.png`
Reference: `SchoolGate_blury.png`. Now shows the front lawn. Used by Elysia `sports_1`, Ulyn `sports_1`, `sports_busy_3`; Kay's `stands_1` has no background at all.
> Match the attached image exactly in style: same camera height, same overcast flat light, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: an empty school sports field in the evening after an event. A running track curving around a grass field, low concrete bleachers on one side, a single folding table with a few stacked paper cups near the track, open empty track in the foreground. Avoid: people, text, clutter, banners, litter, bright or saturated colors, sharp detail, high contrast.

### 3. Krapaostore — `KrapaoStall_blur.png`
Reference: `Cafeteria_blury.png`. Now shows the plain cafeteria. Used by Kay `food_kp_3`.
> Match the attached image exactly in style: same camera height, same dim flat light, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: the same kind of school cafeteria, seen from inside a food line. A clean steel serving counter with a few trays of rice dishes and fried eggs under a glass sneeze guard, a stack of plastic trays, an empty queue rail, open floor in the foreground. Avoid: people, text, menus with words, clutter, steam, bright or saturated colors, sharp detail, high contrast.

### 4. Noodlesstore — `NoodleStall_blur.png`
Reference: `Cafeteria_blury.png`. Now shows the plain cafeteria. Used by Kay `food_nd_3`.
> Match the attached image exactly in style: same camera height, same dim flat light, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: the same kind of school cafeteria, looking down a long empty queue toward a noodle soup counter. A few large steel soup pots, a neat stack of bowls, a long queue rail leading to it, open floor in the foreground. Avoid: people, text, menus with words, clutter, steam, bright or saturated colors, sharp detail, high contrast.

### 5. Kaopadstore — `FriedRiceStall_blur.png`
Reference: `Cafeteria_blury.png`. Now shows the plain cafeteria. Used by Kay `food_fr_3`.
> Match the attached image exactly in style: same camera height, same dim flat light, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: the same kind of school cafeteria, a small fried rice counter with a short queue rail. One wok on a stove behind the counter, a few plates of fried rice on the counter, a stack of plastic trays, open floor in the foreground. Avoid: people, text, menus with words, clutter, flames, steam, bright or saturated colors, sharp detail, high contrast.

### 6. Library (also wanted by the study scenes) — `SchoolLibrary_blur.png`
Reference: `Classroom_blury.png`. Now shows the hallway. Used by Ulyn `lunch_window_1`. Kay `study_1` and Elysia `study_1` have no background at all.
> Match the attached image exactly in style: same camera height, same dim flat light with soft window light, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: a quiet school library on the second floor. Tall tidy bookshelves along one side, one wooden study table at the back with two chairs and a desk lamp, a large window looking out over the school grounds, open floor in the foreground. Avoid: people, text, clutter, posters, bright or saturated colors, sharp detail, high contrast.

### 7. Guidance room — `GuidanceRoom_blur.png`
Reference: `Classroom_blury.png`. Now shows the classroom. Used by Kay `guide_in_1`, `endA_thursdays_1`.
> Match the attached image exactly in style: same camera height, same dim flat light with soft window light, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: a small, calm school counselor's room. Two soft armchairs facing each other, a low table with a teapot and two cups, one potted plant, a window with blinds, a door with a few paper flowers taped on it. Avoid: people, text, clutter, posters with words, bright or saturated colors, sharp detail, high contrast.

### 8. Art room — `ArtRoom_blur.png`
Reference: `Classroom_blury.png`. Now shows the classroom. Used by Elysia `nam_1`, `art_1`.
> Match the attached image exactly in style: same camera height, same dim flat light with soft window light, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: a school art room. A few large shared work tables, jars of brushes, a couple of easels in the corner, a few simple drawings pinned on one wall, large windows, open floor in the foreground. Avoid: people, text, clutter, paint splatter, mess, bright or saturated colors, sharp detail, high contrast.

### 9. Council room — `CouncilRoom_blur.png`
Reference: `Classroom_blury.png`. Now shows the classroom. Used by Ulyn `council_1`, `busy_1`, `sports_busy_2`, `where_21`, `endC_1`.
> Match the attached image exactly in style: same camera height, same dim fluorescent light, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: a small student council meeting room. One long table with a few folders and a megaphone on it, plastic chairs around it, a whiteboard with faint unreadable marks, a few boxes stacked neatly against the wall. Avoid: people, text, clutter, mess, bright or saturated colors, sharp detail, high contrast.

---

## Around town

### 10. Convenience store night (**new**) — `ConvenienceStoreNight_blur.png`
Reference: `Hallway_blury.png`. Now shows Kay's bedroom (Kay `shop_2`) and Elysia's bedroom (Elysia `shop_3`). Neither scene ever switches background.
> Match the attached image exactly in style: same camera height, same flat fluorescent light, same desaturated grey color grade, same soft blur over the whole frame, same quiet empty mood. Create: inside a small 24-hour convenience store late at night. Two tidy aisles of snacks, a glass fridge of drinks along the back wall, a small counter with a sandwich warmer, glass doors showing the dark street outside. Avoid: people, text, logos, brand names, clutter, bright or saturated colors, sharp detail, high contrast.

### 11. Street night (**new**) — `StreetNight_blur.png`
Reference: `sidewalk_blur.png`. Now shows a bedroom. Used by the walk to the bus stop: Kay `shop_out_1`, `shop_walk_1`, Elysia `shop_out_1`.
> Match the attached image exactly in style: same camera height, same wet pavement, same desaturated grey color grade, same soft blur over the whole frame, same quiet empty mood, but at night. Create: a quiet residential street at night. A long sidewalk under a few streetlights, the soft glow of a small store at the corner, a covered bus stop further down the street, low houses behind fences. Avoid: people, cars, text, signs with words, clutter, bright or saturated colors, sharp detail, high contrast.

### 12. Canal park — `CanalPark_blur.png`
Reference: `sidewalk_blur.png`. Now shows the daytime sidewalk. Used by Kay `sat_3`, Elysia `sat_2`.
> Match the attached image exactly in style: same camera height, same overcast flat light, same desaturated grey color grade, same soft blur over the whole frame, same quiet empty mood. Create: a small quiet park beside a calm canal on a grey morning. One bench facing the water, a few trees overhead, a paved path along the edge, buildings faint on the far bank. Avoid: people, animals, text, clutter, litter, bright or saturated colors, sharp detail, high contrast.

### 13. Museum — `MuseumSlimeRoom_blur.png`
Reference: `Hallway_blury.png`. Now shows the school hallway. Used by Kay `sat_museum_1`, Elysia `sat_museum_1`, `endA_1`.
> Match the attached image exactly in style: same camera height, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood, but dimmer. Create: a dim, quiet back room of an old natural history museum. A few wooden glass display cases with small specimen trays inside, soft spotlights on the cases, a dark wooden floor, an open doorway to a brighter hall behind. Avoid: people, text, readable labels, dinosaurs, clutter, bright or saturated colors, sharp detail, high contrast.

### 14. Bus — `BusInterior_blur.png`
Reference: `sidewalk_blur.png`. Now shows the daytime sidewalk. Used by Elysia `endA_end_3`.
> Match the attached image exactly in style: same desaturated grey color grade, same soft blur over the whole frame, same quiet empty mood. Create: inside an empty city bus in the late afternoon. Rows of plain seats, hanging handles, windows with soft blurred streets and pale light outside, the aisle open in the foreground. Avoid: people, text, ads, signs with words, clutter, bright or saturated colors, sharp detail, high contrast.

### 15. Bus stop — `BusStopNight_blur.png`
Reference: `sidewalk_blur.png`. Now shows the daytime sidewalk. Used by Ulyn `bus_1` (7 p.m.).
> Match the attached image exactly in style: same camera height, same wet pavement, same desaturated grey color grade, same soft blur over the whole frame, same quiet empty mood, but at dusk. Create: a simple covered bus stop at dusk. A metal bench under a small roof, a single streetlight just turning on, an empty road beside it, open sidewalk in the foreground. Avoid: people, cars, text, signs with words, clutter, bright or saturated colors, sharp detail, high contrast.

---

## Kay's home

### 16. Kay's kitchen — `KayKitchenDay_blur.png`
Reference: `BedroomDay_blury.png`. Now shows Kay's bedroom. Used by Kay `tue_shower_3`, `endA_fridge_1`.
> Match the attached image exactly in style: same camera height, same soft morning light, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: a small, plain kitchen in the same house. A white fridge with two small sticky notes on the door, a kettle on a clean counter, a small table with two chairs, a window with pale morning light. Avoid: people, text, readable notes, clutter, dishes piled up, bright or saturated colors, sharp detail, high contrast.

### 17. Kay's kitchen night — `KayKitchenNight_blur.png`
Reference: `bedroomnight_blur.png`. Now shows Kay's bedroom at night. Used by Kay `mom_1`.
> Match the attached image exactly in style: same camera height, same very dark night lighting, same desaturated grey color grade, same soft blur over the whole frame, same quiet empty mood. Create: the same small plain kitchen at night, lit by one dim ceiling light. A white fridge with two small sticky notes, a small table with two chairs, a pair of work shoes by the doorway, a dark window. Avoid: people, text, readable notes, clutter, bright or saturated colors, sharp detail, high contrast.

---

## Elysia's home

### 20. Elysia's room — `ElysiaRoomDay_blur.png`
Reference: `BedroomDay_blury.png`. Now shows Kay's bedroom. Used by Elysia `walk_18`, `tue_1`, `mid_sorry_2`.
> Match the attached image exactly in style: same camera height, same soft daylight, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: a different bedroom, a teenage girl's. A neatly made bed with a phone on the pillow, a tidy desk with a small stack of study cards, a shelf with a few books, a string of unlit fairy lights, a curtained window. Avoid: people, text, clutter, posters with words, bright or saturated colors, sharp detail, high contrast.

### 21. Elysia's room night — `ElysiaRoomNight_blur.png`
Reference: `bedroomnight_blur.png`. Now shows Kay's bedroom at night. Used by Elysia `start`, `mid_1`, `thu_night_1`, `late_1`, `note_5`, `endB_3`, `endC_2`.
> Match the attached image exactly in style: same camera height, same very dark night lighting, same desaturated grey color grade, same soft blur over the whole frame, same quiet empty mood. Create: the same teenage girl's bedroom at 1 a.m. Dark, the only light a phone glowing face up on the pillow, a tidy desk with study cards, a closet door slightly open. Avoid: people, text, clutter, bright or saturated colors, sharp detail, high contrast.

### 22. Elysia's kitchen (also for the family dinner) — `ElysiaKitchen_blur.png`
Reference: `BedroomDay_blury.png`. Now shows Kay's bedroom. Used by Elysia `bfast_1`, `pun_1`, `mid_3`. Kay `dinner_2` (still on the garden) and Elysia `dinner_2` (still on Pun's room) should use it too.
> Match the attached image exactly in style: same camera height, same soft warm light, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: a warm, tidy family kitchen with a dining table. A rice cooker on the counter, a few covered dishes and bowls on the table, a small glass jar with a twig on the windowsill, a school bag on one chair. Avoid: people, text, clutter, mess, bright or saturated colors, sharp detail, high contrast.

### 23. Pun's room — `PunRoom_blur.png`
Reference: `BedroomDay_blury.png`. Now shows Kay's bedroom. Used by Elysia `pun_hide_3`, `pun_bug_4`, `note_6`.
> Match the attached image exactly in style: same camera height, same soft late-afternoon light, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: a young boy's small bedroom. A single bed, a little desk with a homework book, two simple bug drawings on the wall, and an empty glass jar with its lid off on the windowsill. Avoid: people, text, clutter, toys everywhere, bright or saturated colors, sharp detail, high contrast.

### 24. Elysia's bathroom (**new**, low priority) — `ElysiaBathroom_blur.png`
Reference: `Bathroom_blur.png`. Now shows Kay's bathroom. Used by Elysia `thu_ulyn_text_3`.
> Match the attached image exactly in style: same camera height, same dim cool light, same desaturated grey color grade, same soft blur over the whole frame, same quiet empty mood. Create: a different small family bathroom at night. A sink with two toothbrushes and a small child's cup, a towel hanging on the door, a ceiling fan vent. Avoid: people, text, clutter, bright or saturated colors, sharp detail, high contrast.

---

## Ulyn, Tan's place and Ulyn's home

### 25. Tan's couch — `TanLivingRoomDay_blur.png`
Reference: `BedroomDay_blury.png`. Now shows Kay's bedroom. Used by Ulyn `start`, `sun_1`, `endB_1`.
> Match the attached image exactly in style: same camera height, same soft early-morning light, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: a small apartment living room. A couch made up as a bed with a folded-back blanket and a pillow, a backpack on the floor beside it, a small TV, a glass balcony door with pale light. Avoid: people, text, clutter, mess, bright or saturated colors, sharp detail, high contrast.

### 26. Tan's couch night — `TanLivingRoomNight_blur.png`
Reference: `bedroomnight_blur.png`. Now shows Kay's bedroom at night. Used by Ulyn `march_1`, `busy_4`, `seven_1`, `mid_text_8`, `bus_tan_3`, `endC_3`.
> Match the attached image exactly in style: same camera height, same very dark night lighting, same desaturated grey color grade, same soft blur over the whole frame, same quiet empty mood. Create: the same small apartment living room at night. The couch made up as a bed with a blanket, a phone glowing on the cushion, one small lamp on, faint city lights through the balcony door. Avoid: people, text, clutter, bright or saturated colors, sharp detail, high contrast.

### 27. Tan's kitchen — `TanKitchenNight_blur.png`
Reference: `bedroomnight_blur.png`. Now shows Kay's bedroom at night. Used by Ulyn `evening_1`, `mid_1`.
> Match the attached image exactly in style: same camera height, same very dark night lighting, same desaturated grey color grade, same soft blur over the whole frame, same quiet empty mood. Create: a tiny apartment kitchenette at night, lit by one small light under the cabinet. A steel sink with two empty noodle cups, a kettle, an open textbook on the narrow counter. Avoid: people, text, clutter, mess, bright or saturated colors, sharp detail, high contrast.

### 28. Tan's balcony — `TanBalconyNight_blur.png`
Reference: `bedroomnight_blur.png`. Now shows Kay's bedroom at night. Used by Ulyn `seven_decline_1`.
> Match the attached image exactly in style: same very dark night lighting, same desaturated grey color grade, same soft blur over the whole frame, same quiet empty mood. Create: a narrow apartment balcony at night. One small stool, a couple of potted plants, a railing, and soft out-of-focus city lights in the distance. Avoid: people, text, clutter, laundry, bright or saturated colors, sharp detail, high contrast.

### 29. Ulyn's kitchen — `UlynKitchenDay_blur.png`
Reference: `BedroomDay_blury.png`. Now shows Kay's bedroom. Used by Ulyn `sun_home_1`, `endA_lunch_1`.
> Match the attached image exactly in style: same camera height, same soft daylight, same desaturated grey-brown color grade, same soft blur over the whole frame, same quiet empty mood. Create: a clean, quiet family kitchen at midday. A dining table set with three plates, a small potted lime tree by a glass balcony door, neat shelves. Avoid: people, text, clutter, bright or saturated colors, sharp detail, high contrast.

### 30. Ulyn's kitchen night — `UlynKitchenNight_blur.png`
Reference: `bedroomnight_blur.png`. Now shows Kay's bedroom at night. Used by Ulyn `evening_home_1`, `bus_home_1`, `endB_porch_1`.
> Match the attached image exactly in style: same camera height, same very dark night lighting, same desaturated grey color grade, same soft blur over the whole frame, same quiet empty mood. Create: the same clean family kitchen at night, only the light over the table on, the rest of the house dark. A dining table set with two plates, a pair of shoes by the door, a porch light glowing through the front window. Avoid: people, text, clutter, bright or saturated colors, sharp detail, high contrast.

### 31. Ulyn's room — `UlynRoomNight_blur.png`
Reference: `bedroomnight_blur.png`. Now shows Kay's bedroom at night. Used by Ulyn `bus_home_19`, `endA_1` (morning), `endA_dad_1`, `endB_garden_7`.
> Match the attached image exactly in style: same camera height, same very dark night lighting, same desaturated grey color grade, same soft blur over the whole frame, same quiet empty mood. Create: a different teenage boy's bedroom that hasn't been slept in for a while. A very neatly made bed, a desk with a few folders, a small shelf with two trophies, a bedside lamp on. Avoid: people, text, clutter, posters with words, bright or saturated colors, sharp detail, high contrast.

---

## Fixable with backgrounds that already exist (no image needed)

These scenes never switch background, so they keep showing the previous place:

| Route | Node | Shows now | Should show |
|---|---|---|---|
| Kay | `vcall_1` (video call at home) | School hallway | Kay's room2 |
| Kay | `joke_1` (garden after school) | School hallway | Garden |
| Elysia | `vcall_1` (video call at home) | Gate | Elysia's room night |
| Elysia | `joke_1` (garden after school) | Art room | Garden |
| Elysia | `ploy_1` (garden, Tuesday) | Cafeteria | Garden |
| Elysia | `home2_1` (waiting at the gate) | School hallway | Gate |
