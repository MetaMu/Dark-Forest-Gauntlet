"""Blender 5.2: non-destructive CC0 prop conversion and original ruin kit.
Run: blender --background --factory-startup --python tools/build_forest_art.py
All dimensions are meters; Blender Z-up becomes Godot Y-up on GLB export.
"""
import bpy, math, random, json, hashlib, shutil
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT/'artifacts/art-upgrade'
OUT = ROOT/'assets/environment/moonlit-ruins'
VENDOR = ROOT/'assets/vendor/quaternius-fantasy'
TEXTURES = ROOT/'assets/vendor/polyhaven-forest'
for p in (OUT,VENDOR,STAGE/'blender'): p.mkdir(parents=True,exist_ok=True)
(STAGE/'blender/.gdignore').touch()
random.seed(83)
receipts=[]

def clear():
    # Imported hidden objects are skipped by select_all; remove every object in
    # this isolated factory-startup scene so imports cannot contaminate exports.
    for obj in list(bpy.context.scene.objects):bpy.data.objects.remove(obj,do_unlink=True)

def export(name,folder=OUT,source='Original Blender-authored geometry'):
    # Keep original downloaded maps intact; resize Blender's imported buffers.
    for image in bpy.data.images:
        if image.size[0]>1024 or image.size[1]>1024:
            image.scale(1024,1024)
            image.pack()
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    for o in meshes:
        bpy.context.view_layer.objects.active=o
        for mod in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=mod.name)
    tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)
    assert tris<60000,(name,tris)
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:o.select_set(True)
    if meshes:
        bpy.context.view_layer.objects.active=meshes[0]
        bpy.ops.object.join()
    path=folder/(name+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_apply=True,export_cameras=False,export_lights=False)
    raw=path.read_bytes(); assert raw[:4]==b'glTF'
    doc=json.loads(raw[20:20+int.from_bytes(raw[12:16],'little')])
    exported_tris=sum(doc['accessors'][p['indices']]['count']//3 for m in doc.get('meshes',[]) for p in m['primitives'])
    assert exported_tris<60000
    receipts.append(dict(file=str(path.relative_to(ROOT)),triangles=exported_tris,blender_triangles=tris,bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest(),source=source))

def mat(name,color,metal=0,rough=.8,emission=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
    if emission:
        p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emission
    return m

def pbr(asset,tint=(1,1,1)):
    m=mat(asset,tint);nodes=m.node_tree.nodes;links=m.node_tree.links;p=nodes.get('Principled BSDF')
    for key,socket in [('diff','Base Color'),('rough','Roughness'),('nor_gl','Normal')]:
        file=next(TEXTURES.glob(asset+'_'+key+'*1k.jpg'))
        tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(file),check_existing=True)
        if key!='diff':tex.image.colorspace_settings.name='Non-Color'
        if key=='nor_gl':
            normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.65
            links.new(tex.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs[0],p.inputs[socket])
        else:links.new(tex.outputs['Color'],p.inputs[socket])
    return m

def finish(o,name,material):
    o.name=name;o.data.materials.append(material);return o

def uv_project(o,size=2):
    uv=o.data.uv_layers.new(name='UVMap') if not o.data.uv_layers else o.data.uv_layers.active
    for poly in o.data.polygons:
        axis=max(range(3),key=lambda i:abs(poly.normal[i]));axes=[i for i in range(3) if i!=axis]
        for li in poly.loop_indices:
            v=o.data.vertices[o.data.loops[li].vertex_index].co
            uv.data[li].uv=(v[axes[0]]/size,v[axes[1]]/size)

def stone(pos,scale,material,bevel=.08,name='Worn masonry'):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for v in o.data.vertices: v.co+=Vector([random.uniform(-.025,.025) for _ in range(3)])
    uv_project(o)
    b=o.modifiers.new('Chipped softened edges','BEVEL');b.width=bevel;b.segments=2
    o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    return finish(o,name,material)

def tube(points,radii,material,name='Gnarled root',sides=10):
    verts=[];faces=[]
    for i,p in enumerate(points):
        tangent=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(i-1,0)])
        q=tangent.to_track_quat('Z','Y')
        for j in range(sides):
            a=j*math.tau/sides;v=q@Vector((math.cos(a)*radii[i],math.sin(a)*radii[i],0))
            verts.append(Vector(p)+v)
    for i in range(len(points)-1):
        for j in range(sides):faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
    faces.extend([tuple(reversed(range(sides))),tuple((len(points)-1)*sides+j for j in range(sides))])
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);uv_project(o,1.5)
    for p in mesh.polygons:p.use_smooth=True
    return finish(o,name,material)

def sphere(pos,scale,material,name='Stone',sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=pos)
    o=bpy.context.object;o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    uv_project(o);return finish(o,name,material)

# Repair broken relative texture paths in staging copies, never provider originals.
source_dir=STAGE/'fantasy-props'
selected=['Axe_Bronze','Sword_Bronze','Shield_Wooden','Torch_Metal','Lantern_Wall','Chest_Wood','Barrel','Crate_Wooden','WeaponStand','Cauldron','Potion_1','Book_7','Banner_1','Anvil_Log','CandleStick_Triple']
for name in selected:
    clear();src=source_dir/'Exports/glTF'/(name+'.gltf');data=json.loads(src.read_text())
    for image in data.get('images',[]):image['uri']=(source_dir/'Textures'/Path(image['uri']).name).as_posix()
    for buf in data.get('buffers',[]):buf['uri']=(src.parent/buf['uri']).as_posix()
    fixed=STAGE/'blender'/(name+'.gltf');fixed.write_text(json.dumps(data))
    bpy.ops.import_scene.gltf(filepath=str(fixed))
    export(name.lower(),VENDOR,'Quaternius Fantasy Props MegaKit Standard / CC0-1.0')
shutil.copyfile(source_dir/'License_Standard.txt',VENDOR/'LICENSE.txt')
shutil.copyfile(STAGE/'fantasy-props-source.json',VENDOR/'source.json')

clear()
rock=pbr('rock_boulder_dry');bark=pbr('bark_brown_02')
moss=mat('Deep olive moss',(.09,.15,.055));iron=mat('Blackened iron',(.065,.085,.095),.7,.35)
gold=mat('Antique brass',(.42,.25,.065),.75,.3)
leaf=mat('Fern jade',(.085,.19,.10));leaf_light=mat('Fern tips',(.19,.28,.105))
glow=mat('Amber glass',(1,.34,.055),0,.28,2)
violet=mat('Spore amethyst',(.40,.07,.32),.2,.35,1.5)

# Nine-meter low wall exactly follows existing cover collision.
for row in range(3):
    for i in range(7):
        x=-3.8+i*1.26
        z=.24+row*.46+random.uniform(-.03,.03)
        stone((x,0,z),(1.20,1.50,.43),rock)
for i in range(12):
    sphere((random.uniform(-4.2,4.2),random.uniform(-.65,.65),1.34),(.30,.20,.09),moss,sub=1)
export('ruined_wall');clear()

# Broken buttress 2.5m footprint. Layered cap and fluted stone shaft.
stone((0,0,.16),(2.45,2.45,.32),rock)
stone((0,0,.42),(2.15,2.15,.22),rock)
for z in [.79,1.32]:stone((0,0,z),(1.65,1.65,.50),rock)
stone((0,0,1.68),(2.10,2.10,.23),rock)
for x in [-.5,0,.5]:stone((x,-.84,1.10),(.12,.09,.78),gold,.02,'Inlaid bronze')
export('ruined_plinth');clear()

# Genuine segmented arch, built around the exit rather than blocking its opening.
for x in [-3.5,3.5]:
    stone((x,0,.25),(1.7,1.9,.5),rock)
    for i in range(5):stone((x,0,.85+i*.64),(1.25,1.45,.60),rock)
    stone((x,0,3.8),(1.7,1.8,.27),rock)
for i in range(13):
    a=(i+.5)*math.pi/13
    o=stone((math.cos(a)*3.5,0,3.7+math.sin(a)*3.5),(.90,1.5,.75),rock)
    o.rotation_euler.y=math.pi/2-a
for x in [-3.5,3.5]:
    tube([(x,0,0),(x-.3,-.8,2),(x+.4,-.7,4),(x*.6,-.4,5.7)],[.23,.2,.12,.015],bark)
export('sanctum_arch');clear()

# Gate visual follows the removable collision body.
for x in [-2.5,-1.5,-.5,.5,1.5,2.5]:
    tube([(x,0,0),(x,.08,1),(x+.2,0,2.2)],[.09,.09,.015],iron,'Portcullis spike',8)
for z in [.45,1.45]:tube([(-2.9,0,z),(2.9,0,z)],[.08,.08],iron,'Cross brace',8)
export('iron_gate');clear()

# Skeletal, tapered trees instead of polygon ball canopies.
for variant in range(3):
    random.seed(700+variant)
    height=7+variant
    tube([(0,0,0),(.15,.1,1.5),(-.25,.1,3.3),(.2,-.1,5.2),(-.4,.25,height)],[.65,.48,.36,.23,.02],bark,'Ancient trunk',14)
    for i in range(7):
        a=i*math.tau/7;dx=math.cos(a);dy=math.sin(a)
        tube([(dx*2.2,dy*2.2,.05),(dx*.9,dy*.9,.25),(0,0,1.3)],[.035,.22,.38],bark,'Buttress root')
    for i in range(8):
        a=i*2.399+variant;z=2.3+i*.43;dx=math.cos(a);dy=math.sin(a)
        end=(dx*(2.2-i*.08),dy*(2.2-i*.08),z+1.8)
        tube([(0,0,z),(dx,dy,z+.4),end,(end[0]+dy*.65,end[1]-dx*.65,end[2]+1)],[.23-i*.016,.15,.07,.008],bark,'Crooked bough')
        tube([(dx,dy,z+.4),(dx*1.6-dy*.6,dy*1.6+dx*.6,z+1.4)],[.1,.005],bark,'Twig',7)
    export('ancient_tree_'+str(variant));clear()

# Fern leaves use folded geometry; no alpha cards or runtime transparency sorting.
for i in range(9):
    a=i*math.tau/9;dx=math.cos(a);dy=math.sin(a)
    for j in range(1,9):
        t=j/9;center=Vector((dx*t,dy*t,math.sin(t*math.pi)*.5))
        for side in [-1,1]:
            length=.25*(1-t)+.05
            tip=center+Vector((-dy*side*length+dx*.1,dx*side*length+dy*.1,-.025))
            wide=Vector((dx*.09,dy*.09,0))
            verts=[center-wide,center+Vector((0,0,.035)),tip,center+wide]
            m=bpy.data.meshes.new('Frond');m.from_pydata(verts,[],[(0,1,2),(1,3,2)])
            o=bpy.data.objects.new('Fern leaflet',m);bpy.context.collection.objects.link(o);finish(o,o.name,leaf if j%2 else leaf_light)
export('fern');clear()

for i in range(5):
    o=sphere((random.uniform(-.6,.6),random.uniform(-.6,.6),.35),(.65,.55,.55),rock)
    for v in o.data.vertices:v.co*=random.uniform(.86,1.15)
export('rubble');clear()

# Raised root-heart altar, only 0.09m tall so no new navigation blocker.
for i in range(24):
    a=i*math.tau/24
    o=stone((math.cos(a)*2.4,math.sin(a)*2.4,.045),(.62,.50,.09),rock,.02)
    o.rotation_euler.z=a
export('ritual_ring');clear()

# Actual rounded 3D bow and realm staffs, grip origin at zero.
tube([(.03,0,-.68),(.24,0,-.50),(.33,0,-.23),(.32,0,0),(.33,0,.23),(.24,0,.5),(.03,0,.68)],[.025,.045,.05,.06,.05,.045,.025],bark,'Carved recurve bow')
for z in [-.15,-.1,-.05,0,.05,.1,.15]:
    tube([(.32,-.055,z),(.32,.055,z)],[.035,.035],gold,'Brass grip wrap',8)
export('ironbark_bow');clear()
for name,gem in [('spore_staff',violet),('light_staff',glow)]:
    tube([(0,0,-.65),(.03,0,0),(0,0,.85)],[.045,.055,.035],bark,'Carved staff')
    for z in [-.2,.0,.2,.70]:
        sphere((0,0,z),(.075,.075,.035),gold,sub=2)
    if name=='spore_staff':
        sphere((0,0,.96),(.25,.16,.20),gem)
        for x in [-1,1]:tube([(0,0,.60),(x*.25,0,.86),(x*.22,0,1.16)],[.045,.04,.005],gold)
    else:
        bpy.ops.mesh.primitive_torus_add(major_radius=.22,minor_radius=.036,major_segments=24,minor_segments=8,location=(0,0,.97),rotation=(math.pi/2,0,0));finish(bpy.context.object,'Sun halo',gold)
        sphere((0,0,.97),(.11,.07,.11),gem)
        for i in range(8):
            a=i*math.tau/8
            tube([(math.cos(a)*.22,0,.97+math.sin(a)*.22),(math.cos(a)*.34,0,.97+math.sin(a)*.34)],[.04,.004],gold)
    export(name);clear()

# Bark-covered adversaries share the forest materials and stepped game animation.
eyes=mat('Soul fire',(1,.42,.07),0,.5,2)
for heart in [False,True]:
    tube([(0,0,.18),(.06,0,.5),(-.05,0,1.05),(.05,0,1.5)],[.36,.52,.43,.20],bark,'Twisted living bole',16)
    for i in range(7):
        a=i*math.tau/7;dx=math.cos(a);dy=math.sin(a)
        tube([(0,0,.6),(dx*.5,dy*.5,.22),(dx*.85,dy*.85,.05)],[.19,.12,.015],bark)
    for side in [-1,1]:
        tube([(side*.28,0,1.1),(side*.65,0,1.45),(side*.55,0,1.95)],[.13,.085,.008],bark,'Antler bough')
        sphere((side*.17,-.39,1.12),(.085,.04,.045),eyes,'Inset amber eye')
        tube([(side*.07,-.42,1.20),(side*.29,-.36,1.25)],[.075,.015],bark,'Heavy brow')
    if heart:
        sphere((0,-.34,.65),(.25,.18,.36),violet,'Corrupted core',2)
        for i in range(5):
            a=i*math.tau/5
            tube([(math.cos(a)*.4,math.sin(a)*.4,.3),(math.cos(a)*.65,math.sin(a)*.65,1),(math.cos(a)*.38,math.sin(a)*.38,1.6)],[.10,.08,.008],bark,'Heart cage')
    export('root_heart' if heart else 'rootling');clear()

# Editable library with spaced modules and packed source materials.
for i,path in enumerate(sorted(OUT.glob('*.glb'))):
    before=set(bpy.context.scene.objects);bpy.ops.import_scene.gltf(filepath=str(path))
    imported=set(bpy.context.scene.objects)-before
    for o in imported:
        if o.parent is None:o.location+=Vector(((i%5)*11,(i//5)*11,0))
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(STAGE/'blender/Moonlit_Ruins_Library.blend'))
(OUT/'receipt.json').write_text(json.dumps({'tool':'Blender '+bpy.app.version_string,'geometry':'Original, except separately credited Quaternius conversions','materials':'Poly Haven CC0-1.0; see assets/vendor/polyhaven-forest/receipt.json','files':receipts},indent=2))
(VENDOR/'receipt.json').write_text(json.dumps([r for r in receipts if 'quaternius' in r['file']],indent=2))
print('ART_BUILD_COMPLETE',len(receipts),'assets')
