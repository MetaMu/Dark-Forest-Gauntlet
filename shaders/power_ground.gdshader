shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(1.0);
uniform float progress = 0.0;
uniform int style = 0;
uniform float intensity = 1.0;
float stroke(float d,float radius,float width){return 1.0-smoothstep(width,width*2.0,abs(d-radius));}
void fragment(){
 vec2 p=(UV-.5)*2.0;
 float d=length(p), a=atan(p.y,p.x);
 float fade=smoothstep(0.0,.08,progress)*(1.0-smoothstep(.48,1.0,progress));
 float shape=0.0;
 if(style==0){
  float wave=mix(.12,.97,min(1.0,progress*3.2));
  float broken=smoothstep(-.5,.4,sin(a*13.0+progress*8.0)+sin(a*23.0)*.5);
  shape=stroke(d,wave,.028)*broken+stroke(d,wave*.87,.018)*.4;
  shape+=(1.0-smoothstep(0.0,.6,d))*(1.0-smoothstep(.0,.3,progress))*.6;
 }else if(style==1){
  float radius=.94+.035*sin(a*11.0+sin(a*7.0)*2.0);
  shape=stroke(d,radius,.009)*(.45+.55*pow(sin(a*8.0),2.0));
  shape+=stroke(d,mix(.1,.93,min(1.0,progress*2.7)),.05)*.20;
  shape+=(1.0-smoothstep(.0,1.0,d))*.055;
 }else if(style==2){
  shape=stroke(d,.96,.005)+stroke(d,.88,.003)*.5;
  float marks=pow(max(0.0,cos(a*16.0)),24.0);
  shape+=marks*smoothstep(.78,.8,d)*(1.0-smoothstep(.91,.92,d))*.75;
  float petals=.32+.15*cos(a*6.0);
  shape+=stroke(d,petals,.007)*.65;
  shape+=stroke(d,.57,.004)*.3;
 }else{
  float noise=sin(p.x*14.0+progress*8.0)*sin(p.y*11.0-progress*6.0);
  shape=(1.0-smoothstep(.05,1.0,d))*(.07+.045*noise);
  shape+=stroke(d,.94+.035*sin(a*9.0),.007)*.24;
 }
 ALBEDO=tint.rgb;
 ALPHA=clamp(shape*fade*intensity,0.0,1.0)*tint.a;
}
