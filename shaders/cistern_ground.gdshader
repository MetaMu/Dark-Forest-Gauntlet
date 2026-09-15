shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D stone : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;TANGENT=vec3(1,0,0);BINORMAL=vec3(0,0,1);}
void fragment(){
 vec2 p=world.xz;
 float channel=1.0-smoothstep(1.1,1.7,abs(abs(p.x)-6.3));
 channel*=smoothstep(-19.0,-16.0,p.y)*(1.0-smoothstep(13.0,16.0,p.y));
 float bridge=max(1.0-smoothstep(1.2,2.0,abs(p.y-7.0)),1.0-smoothstep(1.1,1.8,abs(p.y+10.0)));
 channel*=1.0-bridge;
 channel=max(channel,smoothstep(23.8,25.0,max(abs(p.x),abs(p.y))));
 float ripple=sin(p.y*4.0+TIME*1.4+sin(p.x*3.0))*.035;
 vec3 paving=texture(stone,p/3.8).rgb*vec3(.40,.47,.43);
 float moss=pow(max(0.0,sin(p.x*.8)*sin(p.y*.9)),3.0);
 paving=mix(paving,vec3(.09,.18,.12),moss*.45);
 ALBEDO=mix(paving,vec3(.025,.17+ripple,.18+ripple),channel);
 NORMAL_MAP=texture(normal_tex,p/3.8).rgb;NORMAL_MAP_DEPTH=.38*(1.0-channel);
 ROUGHNESS=mix(.87,.22,channel);METALLIC=channel*.28;
 EMISSION=vec3(.015,.07,.06)*channel;
}
