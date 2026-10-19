"""Build only the four textured buildings. Run with Blender 4.2+ or pip bpy.

Coordinates are meters, Z up, front = -Y. All mesh origins and the exported
root are at (0, 0, 0), the ground-plane center of each building's footprint.
"""
from pathlib import Path
import math
import bpy

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/models/buildings'
TEXTURES = ROOT / 'docs/textures'


def material(name, roughness=0.85, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    tex = mat.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image = bpy.data.images.load(str(TEXTURES / (name + '.png')), check_existing=True)
    tex.extension = 'REPEAT'
    mat.node_tree.links.new(tex.outputs['Color'], bsdf.inputs['Base Color'])
    tex.image.pack()
    return mat


def box(name, size, center):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return obj


def cut(obj, name, size, center):
    cutter = box(name, size, center)
    bpy.context.view_layer.objects.active = obj
    mod = obj.modifiers.new(name, 'BOOLEAN')
    mod.operation = 'DIFFERENCE'
    mod.solver = 'EXACT'
    mod.object = cutter
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter, do_unlink=True)


def shell(name, width, depth, height, thickness=0.2):
    obj = box(name, (width, depth, height), (0, 0, height / 2))
    # Hollow interior, open underneath; roof is part of the shell.
    cut(obj, 'Interior', (width-2*thickness, depth-2*thickness, height), (0, 0, height/2-thickness))
    return obj


def finish(obj, mat):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
    bpy.ops.object.mode_set(mode='OBJECT')
    # Keep smart-project islands; repeat the texture instead of stretching it.
    for loop in obj.data.uv_layers.active.data:
        loop.uv *= max(obj.dimensions) / 2
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')


def garage(m):
    obj = shell('Garage concrete shell', 10, 8, 4)
    cut(obj, '4m x 3m garage opening', (4, 0.8, 3.1), (0, -3.9, 1.45))
    finish(obj, m['concrete_wall'])


def sniper_tower(m):
    wood = m['wood_plank']
    for x in (-1.8, 1.8):
        for y in (-1.8, 1.8):
            finish(box('Tower pillar', (.4, .4, 9.8), (x, y, 4.9)), wood)
    finish(box('Platform top at 8m', (4, 4, .25), (0, 0, 7.875)), wood)
    finish(box('Tower roof', (4, 4, .2), (0, 0, 9.9)), wood)
    for z in (8.45, 9.0):
        for y in (-1.9, 1.9):
            finish(box('Horizontal railing', (3.8, .12, .12), (0, y, z)), wood)
        for x in (-1.9, 1.9):
            finish(box('Side railing', (.12, 3.8, .12), (x, 0, z)), wood)
    for x, y in ((-1.9,0),(1.9,0),(0,-1.9),(0,1.9)):
        finish(box('Railing baluster', (.12, .12, 1.05), (x,y,8.525)), wood)


def house_small(m):
    # 3.5m total height including a 0.65m single-slope roof.
    obj = shell('Brick house walls', 6, 6, 2.85)
    cut(obj, 'House door', (1.2, .8, 2.3), (0, -2.9, 1.05))
    for x in (-1.9, 1.9):
        cut(obj, 'Window opening', (1.1, .8, 1), (x, -2.9, 1.85))
    finish(obj, m['brick_wall'])
    # Wedge roof closes the space above the walls without exceeding footprint.
    verts = [(-3,-3,2.85),(3,-3,2.85),(3,3,2.85),(-3,3,2.85),
             (-3,-3,2.95),(3,-3,2.95),(3,3,3.5),(-3,3,3.5)]
    faces = [(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)]
    mesh = bpy.data.meshes.new('Slanted roof mesh')
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    roof = bpy.data.objects.new('Slanted wooden roof', mesh)
    bpy.context.collection.objects.link(roof)
    finish(roof, m['wood_plank'])


def warehouse(m):
    metal = m['metal_corrugated']
    obj = shell('Corrugated warehouse shell', 15, 10, 6)
    cut(obj, '5m x 4.5m loading opening', (5, .8, 4.6), (0,-4.9,2.2))
    finish(obj, metal)
    # Two partially open sliding leaves inside the facade plane; combined
    # closed coverage is 5m x 4.5m, leaving a 2m visible entrance gap.
    for x in (-2.25, 2.25):
        finish(box('Sliding door leaf', (2.5,.1,4.5), (x,-4.96,2.25)), metal)
    finish(box('Sliding door track', (8,.18,.12), (0,-4.9,4.65)), metal)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, build in [('garage', garage), ('sniper_tower', sniper_tower),
                        ('house_small', house_small), ('warehouse', warehouse)]:
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.delete(use_global=False)
        scene = bpy.context.scene
        scene.unit_settings.system = 'METRIC'
        scene.unit_settings.scale_length = 1.0
        mats = {n: material(n, .6 if n == 'metal_corrugated' else .85,
                            .65 if n == 'metal_corrugated' else 0)
                for n in ('brick_wall','wood_plank','metal_corrugated','concrete_wall')}
        build(mats)
        meshes = [o for o in scene.objects if o.type == 'MESH']
        assert meshes and all(o.location.length < 1e-6 and o.data.uv_layers for o in meshes)
        root = bpy.data.objects.new(name, None)
        scene.collection.objects.link(root)
        for obj in meshes:
            obj.parent = root
        bpy.ops.export_scene.gltf(filepath=str(OUT / (name + '.glb')),
                                  export_format='GLB', export_image_format='AUTO',
                                  export_yup=True, export_texcoords=True,
                                  export_materials='EXPORT')
        print('Exported', name)


if __name__ == '__main__':
    main()
