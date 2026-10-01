"""Reuse the owner-supplied KnowME skin/rig; tailor five realm costumes and combat clips."""
import bpy,math,json,hashlib,bmesh
from pathlib import Path
from mathutils import Vector,Quaternion
R=Path(__file__).resolve().parents[1]
SRC=Path(r'C:/Users/rosec/OneDrive/Documents/Gnome Pear Club EXPO/Character Library/Original Five - Regular Avatars/KnowME - Regular/3D Model - Atlas/Finished Rig v4/KnowME-Finished-Rig.glb')
OUT=R/'assets/characters/gnomes/rigged';OUT.mkdir(parents=True,exist_ok=True)
WORK=R/'artifacts/overhaul';WORK.mkdir(parents=True,exist_ok=True)
IDS=['universal','ember_hollow','ironbark','spore_grove','light_realm']
COLORS=[((.95,.51,.06),(.1,.32,.23)),((.7,.09,.015),(.22,.075,.025)),((.17,.27,.08),(.19,.25,.08)),((.28,.28,.045),(.29,.22,.09)),((.98,.61,.08),(.93,.86,.64))]
receipts=[]
def mat(n,c,metal=0):
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.68;return m
def bind(o,bone):
 bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);o.select_set(False)
 g=o.vertex_groups.new(name=bone);g.add(list(range(len(o.data.vertices))),1,'REPLACE');o.modifiers.new('Realm skin','ARMATURE').object=rig;o.parent=rig
 for p in o.data.polygons:p.use_smooth=True
 return o
def ball(n,pos,scale,m,bone='chest'):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=10,location=pos);o=bpy.context.object;o.name=n;o.scale=scale;o.data.materials.append(m);return bind(o,bone)
def line(n,a,b,r,m,bone='chest'):
 a,b=Vector(a),Vector(b);bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=r,depth=(b-a).length,location=(a+b)/2);o=bpy.context.object;o.name=n;o.rotation_mode='QUATERNION';o.rotation_quaternion=(b-a).to_track_quat('Z','Y');o.data.materials.append(m);return bind(o,bone)
def hat(m):
 rings=[(0,0,.782,.145), (0,0,.802,.153),(0,0,.83,.143),(.008,.005,.89,.117),(.027,.006,.965,.082),(.065,.005,1.023,.048),(.106,.003,1.028,.026),(.126,0,1.001,.006)]
 vs=[];fs=[]
 for x,y,z,r in rings:
  for i in range(32):
   a=math.tau*i/32;vs.append((x+r*math.cos(a),y+r*.86*math.sin(a),z))
 for j in range(len(rings)-1):
  for i in range(32):a=j*32+i;b=j*32+(i+1)%32;fs.append((a,b,b+32,a+32))
 fs.append(tuple(reversed(range(32))));fs.append(tuple(range(224,256)))
 me=bpy.data.meshes.new('Floppy stitched cap');me.from_pydata(vs,[],fs);o=bpy.data.objects.new('Realm cap',me);bpy.context.collection.objects.link(o);me.materials.append(m);bind(o,'head')
def pose(name,axis,angle):
 p=rig.pose.bones.get(name)
 if p:p.rotation_quaternion=Quaternion(p.bone.matrix_local.to_quaternion().inverted()@Vector(axis),angle)
def clip(name,seconds,kind):
 rig.animation_data_create();a=bpy.data.actions.new(name);rig.animation_data.action=a
 frames=round(seconds*24)
 for f in range(frames+1):
  t=f/frames;wave=math.sin(t*math.tau)
  for p in rig.pose.bones:p.rotation_mode='QUATERNION';p.rotation_quaternion=Quaternion();p.location=(0,0,0)
  for side,sign in [('L',1),('R',-1)]:
   pose('upper_arm.'+side,(0,1,0),sign*.45)
   for digit in ['index','middle','ring','pinky']:pose(digit+'.01.'+side,(0,sign,0),.25)
  pose('chest',(1,0,0),.018*wave)
  if kind=='walk':
   for side,sign in [('L',1),('R',-1)]:
    pose('thigh.'+side,(1,0,0),sign*.32*wave);pose('shin.'+side,(1,0,0),max(0,-sign*wave)*.38);pose('upper_arm.'+side,(1,0,0),-sign*.22*wave)
  elif kind in ['attack','cast']:
   # Anticipation -> contact at 55% -> recovery. Bone motion, no object bobbing.
   strength=(t/.42 if t<.42 else (1-(t-.42)/.2 if t<.62 else 0))
   if kind=='cast':
    for side,sign in [('L',1),('R',-1)]:pose('upper_arm.'+side,(1,0,0),-1.05*math.sin(math.pi*t));pose('forearm.'+side,(1,0,0),-.4*math.sin(math.pi*t))
   else:
    pose('chest',(0,0,1),-.38*strength);pose('upper_arm.R',(1,0,0),-1.25*strength);pose('forearm.R',(1,0,0),-.6*strength)
    if ident=='ironbark':
     pose('upper_arm.L',(0,1,0),-.4);pose('forearm.R',(0,0,1),1.1*strength)
    elif ident in ['spore_grove','light_realm']:
     pose('upper_arm.R',(1,0,0),-.55*strength);pose('forearm.L',(1,0,0),-.7*strength)
  elif kind=='hit':pose('chest',(1,0,0),-.28*math.sin(math.pi*t));pose('head',(1,0,0),.12*math.sin(math.pi*t))
  elif kind=='down':
   k=min(1,t*1.6);pose('root',(1,0,0),-math.pi/2*k);rig.pose.bones['root'].location.z=.15*k
  for p in rig.pose.bones:p.keyframe_insert('rotation_quaternion',frame=f+1);p.keyframe_insert('location',frame=f+1)
 rig.animation_data.action=None;track=rig.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,1,a)
 return a
for idx,ident in enumerate(IDS):
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(SRC));rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
 rig.animation_data_clear()
 for o in list(bpy.context.scene.objects):
  if o.type=='MESH' and (o.name.startswith('Icosphere') or 'spiral' in o.name.lower() and not o.name.startswith('Clean')):bpy.data.objects.remove(o,do_unlink=True)
 for o in bpy.context.scene.objects:
  if o.type=='MESH':o.animation_data_clear()
 body=bpy.data.objects['Mesh_0'];body.shape_key_clear()
 bm=bmesh.new();bm.from_mesh(body.data);bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.calc_center_median().z>.775],context='FACES');bm.to_mesh(body.data);bm.free()
 # Preserve skin UVs and sculpted beard; replace the costume material only.
 capmat=mat('Woven realm cap',COLORS[idx][0]);cloth=mat('Realm woven coat',COLORS[idx][1]);leather=mat('Oiled brown leather',(.11,.049,.024));gold=mat('Old gold trim',(.73,.4,.07),.65);ivory=mat('Warm linen',(.86,.81,.64));green=mat('Forest foliage',(.13,.23,.055));purple=mat('Plum cloak',(.21,.045,.095));red=mat('Mushroom crimson',(.48,.025,.025))
 body.data.materials.append(cloth);ci=len(body.data.materials)-1
 for p in body.data.polygons:
  c=p.center
  if .28<c.z<.54 and (c.y>-.07 or c.z<.42 or abs(c.x)>.15):p.material_index=ci
 hat(capmat)
 for sign in [-1,1]:
  ball('Amber iris',(sign*.055,-.159,.713),(.022,.008,.025),gold,'head');ball('Deep pupil',(sign*.055,-.167,.713),(.011,.004,.019),leather,'head');ball('Eye glint',(sign*.055-.005,-.171,.723),(.004,.002,.005),ivory,'head')
  ball('Belt pouch',(sign*.16,-.115,.325),(.043,.026,.048),leather,'pelvis')
 for z in [.32,.38,.44]:ball('Coat clasp',(0,-.139,z),(.014,.009,.014),gold)
 line('Leather waist belt',(-.17,-.124,.34),(.17,-.124,.34),.016,leather,'pelvis')
 if ident=='ember_hollow':
  for side,sign in [('L',1),('R',-1)]:
   ball('Forged shoulder',(sign*.19,0,.493),(.087,.091,.038),leather,'upper_arm.'+side)
   for j in range(4):ball('Copper shoulder rivet',(sign*(.15+j*.022),-.073,.498),(.008,.007,.009),gold,'upper_arm.'+side)
  for j in range(3):ball('Flame emblem',((j-1)*.015,-.15,.43),(.009,.006,.026-j*.004),capmat)
 elif ident=='ironbark':
  for sign in [-1,1]:
   for j in range(6):
    o=ball('Layered oak mantle',(sign*(.07+j*.027),-.075,.51-j*.008),(.026,.018,.065),green);o.rotation_euler.y=sign*.4
  line('Quiver',(.1,.12,.28),(.2,.12,.56),.04,leather)
  for j in range(5):line('Arrow shaft',(.11+j*.011,.12,.39),(.22+j*.011,.12,.68),.0035,ivory)
 elif ident=='spore_grove':
  ball('Plum travelling cape',(0,.10,.40),(.195,.058,.18),purple)
  for x,z in [(-.115,.837),(-.06,.886),(.09,.842)]:
   line('Mushroom stem',(x,-.10,z-.025),(x,-.10,z+.014),.006,ivory,'head');ball('Mushroom cap',(x,-.10,z+.015),(.027,.024,.014),red,'head');ball('Cap spot',(x-.009,-.115,z+.023),(.006,.004,.004),ivory,'head')
 elif ident=='light_realm':
  for sign in [-1,1]:ball('Ivory mantle',(sign*.115,-.01,.516),(.1,.113,.032),ivory)
  for a in range(8):
   ang=a*math.tau/8;line('Sunburst',(0,-.153,.425),(.039*math.sin(ang),-.153,.425+.039*math.cos(ang)),.0045,gold)
  ball('Sun heart',(0,-.157,.425),(.016,.005,.016),gold)
 animations=[clip('Idle',2,'idle'),clip('Walk',.8,'walk'),clip('Attack',.6,'attack'),clip('Cast',.8,'cast'),clip('Hit',.4,'hit'),clip('Down',.8,'down')]
 for p in rig.pose.bones:p.matrix_basis.identity()
 bpy.context.scene.frame_set(1)
 # Join compatible skinned parts to reduce draw objects. Material slots are preserved.
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];bpy.ops.object.select_all(action='DESELECT')
 for o in meshes:o.select_set(True)
 bpy.context.view_layer.objects.active=body;bpy.ops.object.join();rig.select_set(True)
 path=OUT/(ident+'.glb')
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_cameras=False,export_lights=False)
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(WORK/(ident+'.blend')))
 raw=path.read_bytes();d=json.loads(raw[20:20+int.from_bytes(raw[12:16],'little')]);tris=sum(d['accessors'][p['indices']]['count']//3 for m in d['meshes'] for p in m['primitives']);receipts.append(dict(id=ident,sha256=hashlib.sha256(raw).hexdigest(),triangles=tris,clips=[a['name'] for a in d.get('animations',[])],bones=len(rig.data.bones),source_sha256=hashlib.sha256(SRC.read_bytes()).hexdigest()))
(WORK/'player-build.json').write_text(json.dumps(receipts,indent=2))
