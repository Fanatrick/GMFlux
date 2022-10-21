uniform vec2 u_uValue;

#define BDEF 256.0

vec2 encodeXY(in float _f, in float _bound) {
	float _half = 32767.;
	float _val = _f * _bound + _half + 256.;
	return vec2(mod(floor(_val), 256.), floor(_val / 256.)) / 255.;
}

void main() {
	gl_FragColor = vec4(encodeXY(u_uValue.x, BDEF), encodeXY(u_uValue.y, BDEF));
}
