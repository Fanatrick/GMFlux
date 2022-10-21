varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_vPosition;

uniform vec3 u_uSize;	// (cellCount, cellSize, texSize)

uniform sampler2D u_uSampler;
uniform vec4 u_uStencil;
uniform vec2 u_uStencilOffset;
uniform vec2 u_uRange;

uniform int u_uComponent;

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
vec2 encodeXY(in float _f, in float _bound) {
	float _half = 32767.;
	float _val = _f * _bound + _half + 256.;
	return vec2(mod(floor(_val), 256.), floor(_val / 256.)) / 255.;
}
float decodeXY(in vec2 _xy, in float _bound) {
	vec2 _v = _xy * 255.;
	float _val = _v.x + _v.y * 256.;
	float _half = 32767.;
	return (_val - _half - 256.) / _bound;
}

void main() {
	if (v_vPosition != clamp(v_vPosition, u_uStencil.xy, u_uStencil.zw)) {
		discard;
	}
	
	vec4 texsamp = texture2D(u_uSampler, (u_uStencilOffset + v_vPosition) / u_uSize.z);
	float height;
	float value;
	vec2 sample;
	
	gl_FragColor = texsamp;
	
	if (u_uComponent <= 0) {
		height = decodeXY(texsamp.xy, BDEF);
		sample = texture2D(gm_BaseTexture, v_vTexcoord).xw;
		value = mix(u_uRange.x, u_uRange.y, sample.x) * sample.y;
		gl_FragColor = vec4(encodeXY(height + value, BDEF), texsamp.zw);
	}
	else if (u_uComponent == 1) {
		height = decodeXY(texsamp.zw, BDEF);
		sample = texture2D(gm_BaseTexture, v_vTexcoord).yw;
		value = mix(u_uRange.x, u_uRange.y, sample.x) * sample.y;
		gl_FragColor = vec4(texsamp.xy, encodeXY(height + value, BDEF));
	}
	
}
