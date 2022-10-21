varying vec2 v_vTexcoord;
varying vec4 v_vColour;

#define BDEF 256.0

vec4 encodeRGBA(in float _f, float _bound) {
	float _half = 8388607.;
	float _val = floor(_f + 256.) + _half;
	vec4 _rgba = vec4(vec3(0.), 255.-floor(fract(abs(_f)) * 255. + .5) );
	_rgba.b = floor(_val / 65536.);
	_rgba.g = floor((_val - _rgba.b * 65536.) / 256.);
	_rgba.r = mod(_val, 256.);
	return _rgba / 255.;
}
float decodeRGBA(in vec4 _rgba, in float _bound) {
	vec4 _v = _rgba * 255.;
	float _half = 8388607.;
	float _val = _v.r + _v.g * 256. + _v.b * 65536.;
	float _int = (_val - _half - 256.);
	float _frac = (_int < 0.) ? (_v.a / 255.) : 1. - (_v.a / 255.);
	return _int + mod(_frac, 1.0);
}

void main() {
    float depth = decodeRGBA(texture2D(gm_BaseTexture, v_vTexcoord), BDEF);
	if (depth < 1.0) discard;
	gl_FragColor = mix(vec4(1.0, 1.0, 1.0, 0.0), vec4(0.4, 0.5, 1.0, 1.0), min(depth / 32.0, 1.0));
	gl_FragColor = mix(gl_FragColor, vec4(0.1, 0.15, 1.0, 1.0), min(depth / 400.0, 1.0));
}
