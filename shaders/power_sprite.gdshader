shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform sampler2D mask_texture : filter_linear_mipmap, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool billboard = true;
void vertex(){
 if(billboard){
  vec3 s=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
  MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*s.x,INV_VIEW_MATRIX[1]*s.y,INV_VIEW_MATRIX[2]*s.z,MODEL_MATRIX[3]);
 }
}
void fragment(){
 float mask=texture(mask_texture,UV).a;
 ALBEDO=tint.rgb*(.8+.4*mask);
 ALPHA=clamp(pow(mask,.62)*tint.a*1.5,0.0,1.0);
}
