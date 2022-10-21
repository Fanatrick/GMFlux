varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_vPosition;

uniform vec3 u_uSize;	// (cellCount, cellSize, texSize)

uniform sampler2D u_uSampler;
uniform vec4 u_uStencil;
uniform vec2 u_uStencilOffset;
uniform vec2 u_uRange;

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
	if (v_vPosition != clamp(v_vPosition, u_uStencil.xy, u_uStencil.zw)) {
		discard;
	}
    float height = decodeRGBA(texture2D(u_uSampler, (u_uStencilOffset + v_vPosition) / u_uSize.z), BDEF);
	vec2 sample = texture2D(gm_BaseTexture, v_vTexcoord).xw;
	float value = mix(u_uRange.x, u_uRange.y, sample.x) * sample.y;
	gl_FragColor = encodeRGBA(max(height + value, 0.0), BDEF);
}
