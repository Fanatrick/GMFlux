varying vec3 v_normal;

uniform vec4 uvs;//UV x,y,w,h

vec3 sky(vec3 r) {
	#define PI 3.14159265358979
	vec2 u = vec2(atan(r.x,r.y)/2.,-asin(r.z))/PI+.5;
	vec3 t = texture2D(gm_BaseTexture, u*uvs.zw+uvs.xy).rgb;
	
	return t;
}

void main() {	
	vec3 r = normalize(v_normal);
	r.z = -r.z;
    gl_FragColor = vec4(sky(r),1);
}