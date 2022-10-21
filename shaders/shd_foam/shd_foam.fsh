varying vec2 v_vTexcoord;
varying vec3 v_vWorldPos;
varying float v_vWaterLevel;
varying float v_vOOB;

float decodeRGBA(in vec4 _rgba, in float _bound) {
	vec4 _v = _rgba * 255.;
	float _half = 8388607.;
	float _val = _v.r + _v.g * 256. + _v.b * 65536.;
	float _int = (_val - _half - 256.);
	float _frac = (_int < 0.) ? (_v.a / 255.) : 1. - (_v.a / 255.);
	return _int + mod(_frac, 1.0);
}

void main() {
	if (v_vOOB <= 0.1) discard;
	
	float fog = min(v_vWorldPos.z/32000., 1.0);
	fog = 1.0 - pow(fog, 8.);
	
	gl_FragColor = texture2D(gm_BaseTexture, v_vTexcoord);
	
	gl_FragColor.a *= fog;
}
