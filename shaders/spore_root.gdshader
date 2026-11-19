shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 tint : source_color = vec4(.6,.4,.2,1.0);
uniform float growth = 0.0;
uniform float height = 1.2;
uniform float offset = 0.0;
varying vec3 local_point;
void vertex(){ local_point=VERTEX; }
void fragment(){
 float reveal=clamp((growth-offset)/(1.0-offset),0.0,1.0);
 if(local_point.y>reveal*height) discard;
 float grain=.82+.18*sin(local_point.y*27.0+local_point.x*33.0+local_point.z*24.0);
 ALBEDO=tint.rgb*grain;
}
