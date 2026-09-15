shader_type spatial;
uniform vec4 base_color : source_color=vec4(.45,.35,.55,1);
varying vec3 local_point;
void vertex(){local_point=VERTEX;}
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
void fragment(){
 float mottling=sin(local_point.x*16.0+sin(local_point.z*11.0))*sin(local_point.z*13.0+local_point.y*8.0);
 float grain=hash(floor(local_point*110.0));
 ALBEDO=base_color.rgb*(.65+.20*mottling+.20*grain);
 ROUGHNESS=.87;
}
