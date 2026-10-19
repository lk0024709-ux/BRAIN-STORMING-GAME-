# Building texture sources

These four PNGs were AI-generated specifically for this building collection.
Each was resized to a 512 px tile and mirrored horizontally/vertically into a
1024 × 1024 RGB repeat. Opposite-edge pixels match exactly, making the maps
seamless in both axes. Mirroring intentionally creates some symmetric detail.
They are color maps, not normal or displacement maps.

The generator uses repeat-wrapped image textures connected to Principled BSDF
Base Color, smart-project UVs, and packed GLB images (AUTO/PNG).

Run with Blender 4.2+: `blender --background --python tools/generate_buildings.py`
or Python 3.11 with `bpy==4.2.0` and `numpy<2` installed:
`python tools/generate_buildings.py`. Then `python tools/validate_buildings.py`.

Blender is Z-up; exported glTF is Y-up. The exported building root and every
mesh origin are (0,0,0), centered on the ground footprint. House dimensions
include its roof. Warehouse doors are shown partially open. No weapons,
vehicles, or nature assets are generated.

`buildings-pages.yml` rebuilds/validates the models and uploads artifacts on
this working branch and PRs. Only main deploys to GitHub Pages.
