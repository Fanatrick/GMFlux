varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_uHeightFactor;
uniform vec2 u_uTexSize;

#define BDEF 256.0

vec2 px = vec2(1.) / u_uTexSize;

vec4 encodeRGBA(in float _f, float _bound) {
	float _half = 8388607.;
	float _val = floor(_f + 256.) + _half;
	vec4 _rgba = vec4(vec3(0.), 255.-floor(fract(abs(_f)) * 255. + .5) );
	_rgba.b = floor(_val / 65536.);
	_rgba.g = floor((_val - _rgba.b * 65536.) / 256.);
	_rgba.r = mod(_val, 256.);
	return _rgba / 255.;
}
float diffuse(sampler2D _tex, vec2 _uvs) {
	float _total = 0.0;
	_total += texture2D(_tex, _uvs + (px.x, 0.) ).r;
	_total += texture2D(_tex, _uvs - (px.x, 0.) ).r;
	_total += texture2D(_tex, _uvs + (0., px.y) ).r;
	_total += texture2D(_tex, _uvs - (0., px.y) ).r;
	float _my = texture2D(_tex, _uvs).r;
	return mix(_my, _total / 4.0, 0.5);
}

void main() {
    float height = diffuse(gm_BaseTexture, v_vTexcoord);
	
	gl_FragColor = encodeRGBA(height * u_uHeightFactor, BDEF);
}
