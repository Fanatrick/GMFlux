varying vec2 v_vTexcoord;
varying vec4 v_vColour;

#define BDEF 256.0

float decodeXY(in vec2 _xy, in float _bound) {
	vec2 _v = _xy * 255.;
	float _val = _v.x + _v.y * 256.;
	float _half = 32767.;
	return (_val - _half - 256.) / _bound;
}

void main() {
	vec4 flux;
    vec4 sample = texture2D(gm_BaseTexture, v_vTexcoord);
	flux.x = decodeXY(sample.xy, BDEF);	// left
	flux.y = decodeXY(sample.zw, BDEF);	// down
	sample = texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.5, 0.0) );
	flux.z = decodeXY(sample.xy, BDEF);	// right
	flux.w = decodeXY(sample.zw, BDEF);	// up
	vec2 flow = flux.zy - flux.xw;
	gl_FragColor = vec4(0.5 + flow.x / 1000., 0.5 + flow.y / 1000., 1.0, 1.0);
}
