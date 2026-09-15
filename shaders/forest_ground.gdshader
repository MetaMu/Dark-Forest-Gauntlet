shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D forest_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D forest_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cobble_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cobble_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){
 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 TANGENT=vec3(1,0,0);BINORMAL=vec3(0,0,1);
}
void fragment(){
 vec2 p=world.xz;
 float edge=noise(p*1.3)*0.65;
 float path=1.0-smoothstep(2.5,3.6,abs(p.x-sin(p.y*.17)*.5)+edge);
 float crosspath=(1.0-smoothstep(2.0,3.1,abs(p.y+11.0)+edge))*(1.0-smoothstep(12.0,15.0,abs(p.x)));
 float clearing=1.0-smoothstep(4.2,5.3,length(p-vec2(0,15))+edge);
 float blend=max(max(path,crosspath),clearing);
 vec3 soil=texture(forest_color,p/5.0).rgb;
 vec3 paving=texture(cobble_color,p/4.0).rgb;
 ALBEDO=mix(soil*vec3(.24,.33,.28),paving*vec3(.43,.49,.53),blend);
 NORMAL_MAP=mix(texture(forest_normal,p/5.0).rgb,texture(cobble_normal,p/4.0).rgb,blend);
 NORMAL_MAP_DEPTH=.28;ROUGHNESS=.98;
}
