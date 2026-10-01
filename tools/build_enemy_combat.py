import bpy,math,json,hashlib
from pathlib import Path
from mathutils import Quaternion,Vector
R=Path(__file__).resolve().parents[1];OUT=R/'assets/owner/atlas';receipts=[]
for ident in ['ironroot-guard','mortarcap','root-heart']:
 bpy.ops.wm.read_factory_settings(use_empty=True);src=R/'reference/production/enemies/mixamo-tests'/f'{ident}-walk-in-place.glb';bpy.ops.import_scene.gltf(filepath=str(src));rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
 walk=next(a for a in bpy.data.actions if a.name=='WalkInPlace');rig.animation_data.action=walk;bpy.context.scene.frame_set(1)
 base={p.name:p.rotation_quaternion.copy() for p in rig.pose.bones};loc={p.name:p.location.copy() for p in rig.pose.bones}
 rig.animation_data_clear();rig.animation_data_create();tr=rig.animation_data.nla_tracks.new();tr.name='WalkInPlace';tr.strips.new('WalkInPlace',1,walk)
 def rotate(short,axis,angle):
  p=rig.pose.bones.get('mixamorig:'+short)
  if p:p.rotation_quaternion=base[p.name]@Quaternion(p.bone.matrix_local.to_quaternion().inverted()@Vector(axis),angle)
 for name,seconds in [('Idle',2),('AttackSwipe',1.2),('HitFlinch',.5),('Death',1.5)]:
  action=bpy.data.actions.new(name);rig.animation_data.action=action
  for f in range(round(seconds*24)+1):
   t=f/(seconds*24)
   for p in rig.pose.bones:p.rotation_mode='QUATERNION';p.rotation_quaternion=base[p.name];p.location=loc[p.name]
   if name=='Idle':rotate('Spine',(1,0,0),.035*math.sin(t*math.tau))
   elif name=='AttackSwipe':
    # Peak contact at 70% matches runtime windup / total duration.
    rise=min(1,t/.5);fall=max(0,1-(t-.5)/.2);strength=rise if t<.5 else fall
    if ident=='ironroot-guard':
     for side in ['Left','Right']:rotate(side+'Arm',(1,0,0),-1.25*strength);rotate(side+'ForeArm',(1,0,0),-.7*strength)
     rotate('Spine',(1,0,0),.3*math.sin(math.pi*t))
    elif ident=='mortarcap':
     rotate('Spine',(1,0,0),.25*math.sin(t*math.pi));rotate('Head',(1,0,0),-.2*strength)
     for side in ['Left','Right']:rotate(side+'Arm',(1,0,0),-.6*strength)
    else:
     rotate('Spine',(1,0,0),.10*math.sin(t*math.pi))
     for side,sgn in [('Left',1),('Right',-1)]:rotate(side+'Arm',(0,1,0),sgn*.3*math.sin(t*math.pi))
   elif name=='HitFlinch':rotate('Spine',(1,0,0),-.2*math.sin(t*math.pi))
   else:
    k=min(1,t*1.5);rotate('Hips',(1,0,0),-1.4*k)
   for p in rig.pose.bones:p.keyframe_insert('rotation_quaternion',frame=f+1);p.keyframe_insert('location',frame=f+1)
  rig.animation_data.action=None;tr=rig.animation_data.nla_tracks.new();tr.name=name;tr.strips.new(name,1,action)
 for p in rig.pose.bones:p.matrix_basis.identity()
 bpy.context.scene.frame_set(1);bpy.ops.object.select_all(action='SELECT');out=OUT/f'{ident}-combat.glb';bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',export_animation_mode='NLA_TRACKS',export_animations=True,export_nla_strips=True)
 receipts.append(dict(file=out.name,source_sha256=hashlib.sha256(src.read_bytes()).hexdigest(),sha256=hashlib.sha256(out.read_bytes()).hexdigest(),animation_source='Existing Mixamo walk; locally authored skeletal idle, signature attack, hit, death'))
(R/'artifacts/overhaul/enemy-build.json').write_text(json.dumps(receipts,indent=2))
