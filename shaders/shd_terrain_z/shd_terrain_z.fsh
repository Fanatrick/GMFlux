varying vec2 v_vTexcoord;
varying float v_vDepth;
varying float v_vOOB;

vec4 encodeRGBA(in float _f, float _bound) {
	float _half = 8388607.;
	float _val = floor(_f + 256.) + _half;
	vec4 _rgba = vec4(vec3(0.), 255.-floor(fract(abs(_f)) * 255. + .5) );
	_rgba.b = floor(_val / 65536.);
	_rgba.g = floor((_val - _rgba.b * 65536.) / 256.);
	_rgba.r = mod(_val, 256.);
	return _rgba / 255.;
}

void main() {
	if (v_vOOB <= 0.1) discard;
    gl_FragColor = encodeRGBA(v_vDepth, 256.0);
	gl_FragColor.a = 1.0;
}
