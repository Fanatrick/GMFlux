varying vec2 v_vTexcoord;
varying vec3 v_vWorldPos;
varying float v_vWaterLevel;
varying vec3 v_vNormal;
varying float v_vOOB;

uniform vec3 u_uLookat;
uniform vec3 u_uSunray;
uniform float u_uFragmentTime;

float decodeRGBA(in vec4 _rgba, in float _bound) {
	vec4 _v = _rgba * 255.;
	float _half = 8388607.;
	float _val = _v.r + _v.g * 256. + _v.b * 65536.;
	float _int = (_val - _half - 256.);
	float _frac = (_int < 0.) ? (_v.a / 255.) : 1. - (_v.a / 255.);
	return _int + mod(_frac, 1.0);
}

vec3 caustics(in vec2 uvs, in float offs) {
	vec2 _offs = vec2(offs, -offs);
	vec3 caust;
	caust.r = texture2D(gm_BaseTexture, uvs + _offs.xx, v_vWorldPos.z/20000.).r;
	caust.g = texture2D(gm_BaseTexture, uvs + _offs.xy, v_vWorldPos.z/20000.).r;
	caust.b = texture2D(gm_BaseTexture, uvs + _offs.yy, v_vWorldPos.z/20000.).r;
	return caust;
}

void main() {
	if (v_vOOB <= 0.1) discard;
	
	vec3 norm = normalize(vec3(v_vNormal.xy, v_vNormal.z * 0.2));
	vec3 sunray = normalize(u_uSunray);
	
	float len = abs(dot(norm, sunray));
	
	gl_FragColor.a = len * min(v_vWaterLevel / 300., 1.0);
	gl_FragColor.a = pow(gl_FragColor.a, 2.0) * 1.0;
	
	float fog = min(v_vWorldPos.z/32000., 1.0);
	fog = 1.0 - pow(fog, 8.);
	
	norm *= norm;
	float vc = 1.2 - length(norm.xy)*.2;
	vec3 c1 = caustics( (v_vWorldPos.xy + norm.xy * len * 1024.0 * vc ) / (4096.) - vec2(1.) * u_uFragmentTime, 0.002 * len);
	vec3 c2 = caustics( (v_vWorldPos.xy + norm.xy * len * 1024.0 * vc ) / (4072.) + vec2(1.35, 0.65) * u_uFragmentTime, 0.003 * len);
	
	gl_FragColor.rgb = min(c1*c1, c2*c2) * 4.0;
	
	gl_FragColor.a *= fog;
	
}
