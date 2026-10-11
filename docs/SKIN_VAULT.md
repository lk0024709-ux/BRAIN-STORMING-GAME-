# Battle Dojo Skin Vault — asset + prompt pack

Everything the shop needs for the six polygon skins is generated, committed, and
wired into the Flutter app. This file is the contract between the art pack, the
generator script, and the game code.

## What ships

| Skin | Frame | Rarity | Border | Heart | Price |
| --- | --- | --- | --- | --- | --- |
| Neon Ninja | hexagon | common | `#00FFFF` | – | 500 coin |
| Cyber Samurai | octagon | rare | `#8A2BE2` | – | 700 coin |
| Shadow Assassin | diamond | epic | `#FF00FF` | – | 600 coin |
| Frost Warrior | pentagon | legendary | `#00BFFF` | red | 800 coin |
| Inferno Mask | triangle | mythic | `#FF4500` | red | 900 coin |
| Golden Emperor | golden hex | ultimate | `#FFD700` | red | 1200 coin |

Fixed style rules from the pack:

* 512×512 PNG, transparent background, centered character bust rendered in 3D
  (octane/PBR photo-real), **not** manga, anime, or flat illustration.
* Glowing rarity border, **8 px** at 512 px.
* Dark space `#0A0E1A` panel with a low-poly neon wireframe grid
  (`#00FFFF` / `#8A2BE2`) and a per-rarity pattern inside the polygon.
* Top row: `Lv.12` chip + coin balance chip, plus a `#FF0000` heart when the
  tier carries one.
* Skin name under the frame, price in coin yellow `#FFD700` with the word
  `coin`, and a `BUY` bar — or the green `EQUIPPED` state.

Files:

```
assets/skins/raw/                       source art straight from the image model (1024×1024)
assets/skins/cards/<skin>.png           store card, BUY state           (512×512)
assets/skins/cards/<skin>_equipped.png  store card, EQUIPPED state      (512×512)
assets/skins/busts/<skin>.png           transparent bust for the hero portrait
assets/skins/store_config.json          generated style guide + store JSON
tools/generate_store_assets.py          the generator (Pillow + numpy)
tools/preview_skin_cards.png            contact sheet of all six BUY cards
```

## Prompt pack used for the busts (3D render, not manga)

The busts are **photoreal 3D renders** — the store brief is "rendered, not
drawn". Every prompt shares this tail:

> 3D rendered character bust, square 1:1, centered chest-up portrait … chest-up
> centered portrait facing viewer, photorealistic octane render, PBR materials,
> hard surface modeling, realistic studio lighting with soft shadows, depth of
> field, high detail, AAA game character render, 8k. Simple flat solid uniform
> dark navy background color `#0A0E1A` with absolutely no gradient, no vignette,
> no glow spill, no grid, no pattern, character centered with a clear empty
> margin around it, no frame, no border, no text, no letters, no numbers, no
> watermark, no logo, single character only.

Per-skin clause:

* **Neon Ninja** — black hooded shinobi, dark armor with glowing cyan `#00FFFF`
  neon trim, glowing cyan visor band over one eye, confident expression.
* **Cyber Samurai** — layered brushed-metal samurai shoulder armor with etched
  tech circuitry, purple `#8A2BE2` energy trim, purple visor, katana hilt
  rising behind the shoulder.
* **Shadow Assassin** — dark hooded cloak, face half hidden in shadow, glowing
  magenta eyes, wisps of purple smoke curling behind the shoulders.
* **Frost Warrior** — ice-blue plated armor with frost shard spikes on the
  shoulders, glowing `#00BFFF` runes, cold mist around the armor.
* **Inferno Mask** — red oni mask pushed up on the forehead, cracked black armor
  with glowing lava seams, `#FF4500` flame particles and embers.
* **Golden Emperor** — ornate gold plated armor with engraved filigree, jeweled
  crown circlet, fur-trimmed cape collar, soft halo of gold light rings.

### Negative prompt (required)

The render step must never fall back to the old anime look. Append this:

```
anime, manga, cartoon, cel shaded, 2d illustration, flat, hand drawn, comic,
sketch, low poly, blurry, distorted, deformed face, cropped head, multiple
characters, frame, border, card, ui, hud, coin, heart, text, letters, numbers,
watermark, logo, background scenery, gradient background, vignette
```

Positive tail for diffusion pipelines: `3d render, octane render, PBR, realistic
lighting, metallic, depth, thickness, photorealistic, Unreal Engine, Blender`.

Vendor notes:

* **Replicate** (`negative_prompt` field) — paste the negative block above.
* **Midjourney / Leonardo** — `--no anime, manga, cartoon, flat, cel shaded,
  text, frame, border, ui, multiple characters` with `--style raw --ar 1:1`.

### Background rule

Keep the backdrop **flat and uniform** — either pure white or the dark `#0A0E1A`
panel — with no gradient, vignette or glow spill. `cut_bust` in
`tools/generate_store_assets.py` keys it out with a corner flood fill
(threshold 30), so a busy backdrop leaks into the cutout.

## Regenerating the assets

```bash
python3 -m pip install Pillow numpy        # or a venv
python3 tools/generate_store_assets.py
```

The script re-renders `assets/skins/cards/`, `assets/skins/busts/`,
`assets/skins/store_config.json` and the contact sheet. Point it at new source
art with `SKIN_RAW_DIR=/path/to/1024px_pngs`. Prompts, prices, colours and frame
shapes all live in the `SPEC` + `SHAPES` tables at the top of the script — edit
those, not the rendered PNGs.

## Wiring in the game

* `assets/skins/store_config.json` is the source of truth for the art pack.
* `lib/models/skin_shop.dart` (`SkinCatalog`) is the runtime mirror; the shop
  reads prices, borders and hearts from it, and `test/skin_shop_test.dart`
  asserts the JSON and the Dart table are identical.
* `lib/widgets/skin_card.dart` renders one store card at any size.
* `ShopScreen` shows the vault; buying deducts coins, equipping swaps the hero
  portrait on `HomeScreen` (`assets/skins/busts/<skin>.png`).
* Owned skins persist in `SharedPreferences` (`owned_skins`, `equipped_skin`)
  and survive a training reset.

## Importing into Unity / React instead

The cards are plain transparent PNGs, so they drop into any engine:

* **Unity** — put the files under `Assets/StreamingAssets/skins/`, import with
  `Texture Type: Sprite (2D and UI)`, `Alpha Is Transparency: true`,
  `Filter Mode: Bilinear`, and slice nothing (each card is self-contained).
* **React/web** — reference `assets/skins/cards/<skin>.png` directly; the cards
  already contain the frame, rarity tag, price and BUY bar, so a `<img>` is
  enough. Use `_equipped` for the owned state.
* Money text is baked as `#FFD700` and hearts as `#FF0000`, matching the
  `coin_color` / `heart_color` keys in the JSON if you would rather draw those
  in-app.
