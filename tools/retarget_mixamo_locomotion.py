"""Retarget documented Mixamo captures to the existing five gnome skins.
Original meshes, combat clips and source motions are preserved. Run in background Blender.
"""
import bpy,math,json,hashlib,shutil,sys,statistics
from pathlib import Path
from mathutils import Vector,Quaternion
R=Path(__file__).resolve().parents[1];W=R/'artifacts/mixamo-locomotion';W.mkdir(parents=True,exist_ok=True)
ARCH=R/'reference/production/player-locomotion-originals';ARCH.mkdir(parents=True,exist_ok=True)
OUT=W/'candidates';OUT.mkdir(exist_ok=True)
LIB=Path(r'C:/Users/rosec/OneDrive/Documents/GLB Refresher Tool/local-assets/garbage-friends-animation')
SOURCES={'Walk':LIB/'mixamo-walk-source/Mixamo-Walking-Swagger-InPlace-24fps.fbx','Run':LIB/'walk-run-v7/Mixamo-Running-With-Intention-24fps.fbx'}
M={'pelvis':'Hips','spine':'Spine','chest':'Spine2','neck':'Neck','head':'Head'}
for side,word in [('L','Left'),('R','Right')]:
 for target,source in [('clavicle','Shoulder'),('upper_arm','Arm'),('forearm','ForeArm'),('hand','Hand'),('thigh','UpLeg'),('shin','Leg'),('foot','Foot'),('toe','ToeBase')]:M[target+'.'+side]=word+source
SOURCES['Cast']=Path(r'D:/Gnome Pear Club Visualizers/01 - Working Projects/lonely-lily-studios-ark-build-timelapse/assets/Motion-Packs/Magic-Spell-Pack/Standing 2H Magic Attack 01.fbx')
FPS=60
motions={}
for name,path in SOURCES.items():
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(path));s=bpy.context.scene;src=next(o for o in s.objects if o.type=='ARMATURE');action=src.animation_data.action;start,end=action.frame_range;duration=(end-start)/s.render.fps;n=round(duration*FPS)
 rest={k:(src.matrix_world@src.data.bones['mixamorig:'+v].matrix_local).to_quaternion() for k,v in M.items()}
 srcleg=sum((src.matrix_world.to_3x3()@(src.data.bones['mixamorig:'+b].tail_local-src.data.bones['mixamorig:'+b].head_local)).length for b in ['LeftUpLeg','LeftLeg'])
 rows=[]
 for i in range(n):
  f=start+(end-start)*i/(n-1 if name=='Cast' else n);s.frame_set(math.floor(f),subframe=f%1);bpy.context.view_layer.update();rows.append({'q':{k:(src.matrix_world@src.pose.bones['mixamorig:'+v].matrix).to_quaternion().copy() for k,v in M.items()},'hip':(src.matrix_world@src.pose.bones['mixamorig:Hips'].matrix).translation.copy()})
 motions[name]=dict(rows=rows,rest=rest,leg=srcleg,duration=duration,n=n,path=str(path),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),source_fps=s.render.fps,source_frames=[start,end])

def smooth(vals,i,r=3):
 weights=[math.exp(-j*j/4) for j in range(-r,r+1)];return sum((vals[(i+j)%len(vals)]*w for j,w in zip(range(-r,r+1),weights)),Vector())/sum(weights)
def set_global(rig,name,q):
 p=rig.pose.bones[name];par=p.parent;base=par.matrix@par.bone.matrix_local.inverted()@p.bone.matrix_local if par else p.bone.matrix_local
 p.rotation_mode='QUATERNION';p.rotation_quaternion=base.to_quaternion().inverted()@q;bpy.context.view_layer.update()
def solve_leg(rig,side,ankle,knee_hint,foot_q):
 thigh=rig.pose.bones['thigh.'+side];shin=rig.pose.bones['shin.'+side];h=thigh.head.copy();d=ankle-h;length=d.length;l1=thigh.bone.length;l2=shin.bone.length;dist=min(length,(l1+l2)*.995);direction=d.normalized();pole=knee_hint-h;pole-=direction*pole.dot(direction)
 if pole.length<1e-5:pole=Vector((0,-1,0));pole-=direction*pole.dot(direction)
 pole.normalize();along=(l1*l1-l2*l2+dist*dist)/(2*max(dist,1e-6));height=math.sqrt(max(0,l1*l1-along*along));k=h+direction*along+pole*height
 for name,a,b in [('thigh.'+side,h,k),('shin.'+side,k,h+direction*dist)]:
  rest=rig.data.bones[name].matrix_local.to_quaternion();q=(rest@Vector((0,1,0))).rotation_difference((b-a).normalized())@rest;set_global(rig,name,q)
 set_global(rig,'foot.'+side,foot_q)
 return max(0,length-dist)
reports=[]
for ident in ['universal','ember_hollow','ironbark','spore_grove','light_realm']:
 original=R/'assets/characters/gnomes/rigged'/f'{ident}.glb';backup=ARCH/original.name
 if not backup.exists():shutil.copy2(original,backup)
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(backup));s=bpy.context.scene;import_fps=s.render.fps;s.render.fps=FPS;rig=next(o for o in s.objects if o.type=='ARMATURE');meshes=[o for o in s.objects if o.type=='MESH' and any(m.type=='ARMATURE' and m.object==rig for m in o.modifiers)];body=max(meshes,key=lambda o:len(o.data.vertices))
 preserved=[]
 for a in list(bpy.data.actions):
  if a.name not in ['Walk','Run','Cast'] and a.slots:preserved.append((a,a.slots[0]))
 rig.animation_data_clear();rig.animation_data_create()
 for p in rig.pose.bones:p.matrix_basis.identity()
 ar={k:rig.data.bones[k].matrix_local.to_quaternion() for k in M};leg=sum(rig.data.bones[b+'.L'].length for b in ['thigh','shin']);groups={g.index:g.name for g in body.vertex_groups};footids={side:[v.index for v in body.data.vertices if sum(g.weight for g in v.groups if groups[g.group] in ['foot.'+side,'toe.'+side])>.55] for side in ['L','R']}
 assert all(footids.values())
 char=dict(id=ident,source_sha256=hashlib.sha256(backup.read_bytes()).hexdigest(),clips={})
 newactions=[]
 for name,motion in motions.items():
  n=motion['n'];ratio=leg/motion['leg'];meanhip=sum((r['hip'] for r in motion['rows']),Vector())/n;raw=[]
  correction={k:(ar[k]@Vector((0,1,0))).rotation_difference(motion['rest'][k]@Vector((0,1,0)))@ar[k] if k.startswith(('upper_arm','forearm','hand')) else ar[k] for k in M}
  for i,row in enumerate(motion['rows']):
   for p in rig.pose.bones:p.matrix_basis.identity()
   for k in M:set_global(rig,k,row['q'][k]@motion['rest'][k].inverted()@correction[k])
   # Source translation relative to its cycle mean; preserve lateral weight shift.
   delta=(row['hip']-meanhip)*ratio;rig.pose.bones['pelvis'].location=ar['pelvis'].inverted()@delta;bpy.context.view_layer.update()
   ev=body.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();low={side:min((ev.matrix_world@me.vertices[v].co).z for v in footids[side]) for side in ['L','R']};ev.to_mesh_clear()
   # Establish original grounded ankle trajectories; smooth hips separately below.
   lift=.002-min(low.values()) if name in ['Walk','Cast'] else 0;rig.pose.bones['pelvis'].location+=ar['pelvis'].inverted()@Vector((0,0,lift));bpy.context.view_layer.update()
   raw.append(dict(low=min(low.values()),q={p.name:p.rotation_quaternion.copy() for p in rig.pose.bones},hip=rig.pose.bones['pelvis'].location.copy(),ankle={side:rig.pose.bones['foot.'+side].head.copy() for side in ['L','R']},knee={side:rig.pose.bones['shin.'+side].head.copy() for side in ['L','R']},footq={side:rig.pose.bones['foot.'+side].matrix.to_quaternion().copy() for side in ['L','R']}))
  if name=='Run':
   offset=Vector((0,0,.002-min(r['low'] for r in raw)))
   for r in raw:
    r['hip']+=ar['pelvis'].inverted()@offset
    for side in ['L','R']:r['ankle'][side]+=offset;r['knee'][side]+=offset
  # Smooth/reduce hip bounce without smoothing away captured swing-foot lift.
  hips=[r['hip'] for r in raw];mean=sum(hips,Vector())/n
  for i,r in enumerate(raw):r['smoothhip']=mean+(smooth(hips,i)-mean)*.7 if name=='Walk' else r['hip']
  # Stance travel estimate is recorded for runtime cadence matching.
  slopes=[]
  for side in ['L','R']:
   ys=[r['ankle'][side].y for r in raw]
   for i in range(n):
    speed=(ys[(i+1)%n]-ys[i])*FPS
    if speed>.02:slopes.append(speed)
  stride=statistics.median(slopes)*motion['duration'] if slopes else leg
  action=bpy.data.actions.new(name+'_Mixamo');rig.animation_data.action=action;previous={};metrics=[]
  for i in range(n+1):
   r=raw[min(i,n-1) if name=='Cast' else i%n]
   for p in rig.pose.bones:p.rotation_mode='QUATERNION';p.rotation_quaternion=r['q'][p.name];p.location=Vector()
   rig.pose.bones['pelvis'].location=r['smoothhip'];bpy.context.view_layer.update()
   reach=[]
   for side in ['L','R']:reach.append(solve_leg(rig,side,r['ankle'][side],r['knee'][side],r['footq'][side]))
   for p in rig.pose.bones:
    if p.name in previous:p.rotation_quaternion.make_compatible(previous[p.name])
    previous[p.name]=p.rotation_quaternion.copy();p.keyframe_insert('rotation_quaternion',frame=i);p.keyframe_insert('location',frame=i)
   ev=body.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();low=min((ev.matrix_world@me.vertices[v].co).z for side in ['L','R'] for v in footids[side]);ev.to_mesh_clear();metrics.append(dict(frame=i,sole_min=low,reach_clamp=max(reach)))
  for layer in action.layers:
   for strip in layer.strips:
    for bag in strip.channelbags:
     for curve in bag.fcurves:
      for key in curve.keyframe_points:key.interpolation='LINEAR'
  newactions.append((name,action,rig.animation_data.action_slot));rig.animation_data.action=None
  char['clips'][name]=dict(duration=motion['duration'],frames=n+1,stride_model_units=stride,source=motion['path'],source_sha256=motion['sha256'],source_fps=motion['source_fps'],source_frames=motion['source_frames'],sole_min=min(x['sole_min'] for x in metrics),sole_max=max(x['sole_min'] for x in metrics),max_reach_clamp=max(x['reach_clamp'] for x in metrics))
  (W/f'{ident}-{name.lower()}-samples.json').write_text(json.dumps(metrics,indent=2))
 for action,slot in preserved:
  tr=rig.animation_data.nla_tracks.new();tr.name=action.name;strip=tr.strips.new(action.name,1,action);strip.action_slot=slot
  # Existing clips were imported at 24 fps. Preserve their seconds at 60 fps.
  strip.scale=FPS/import_fps
 for name,action,slot in newactions:
  tr=rig.animation_data.nla_tracks.new();tr.name=name;strip=tr.strips.new(name,0,action);strip.action_slot=slot
 bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
 for o in meshes:o.select_set(True)
 s.frame_set(1);bpy.ops.export_scene.gltf(filepath=str(OUT/(ident+'.glb')),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_cameras=False,export_lights=False)
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(W/(ident+'.blend')))
 char['sha256']=hashlib.sha256((OUT/(ident+'.glb')).read_bytes()).hexdigest();reports.append(char);(W/'retarget-report.json').write_text(json.dumps(reports,indent=2));print('RETARGETED',ident,char['clips'],flush=True)
