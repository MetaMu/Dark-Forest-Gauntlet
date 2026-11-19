shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform sampler2D mask_texture : filter_linear_mipmap, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool billboard = true;
uniform float progress = 0.0;
void vertex(){
 if(billboard){
  vec3 s=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
  MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*s.x,INV_VIEW_MATRIX[1]*s.y,INV_VIEW_MATRIX[2]*s.z,MODEL_MATRIX[3]);
 }
}
void fragment(){
 vec2 uv=UV;
 // Bend the free Kenney mask into rising tongues; fade to red at the tip.
 uv.x+=sin(UV.y*13.0-progress*12.0)*.045*(1.0-UV.y);
 float mask=texture(mask_texture,uv).a;
 float erosion=progress*.28;
 float edge=smoothstep(erosion,erosion+.22,mask);
 vec3 core=mix(tint.rgb,vec3(1.0,.82,.28),smoothstep(.45,.95,mask)*.65);
 ALBEDO=core;
 ALPHA=edge*tint.a;
}
