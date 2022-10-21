varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform sampler2D u_uSampler;
uniform float u_uFragTime;

#define BDEF 256.0

float decodeXY(in vec2 _xy, in float _bound) {
	vec2 _v = _xy * 255.;
	float _val = _v.x + _v.y * 256.;
	float _half = 32767.;
	return (_val - _half - 256.) / _bound;
}

void main() {
	// get flux
	vec4 flux;
    vec4 sample = texture2D(u_uSampler, v_vTexcoord * 0.5 + vec2(0.0, 0.5) );
	flux.x = decodeXY(sample.xy, BDEF);	// left
	flux.y = decodeXY(sample.zw, BDEF);	// down
	sample = texture2D(u_uSampler, v_vTexcoord * 0.5 + vec2(0.5, 0.5) );
	flux.z = decodeXY(sample.xy, BDEF);	// right
	flux.w = decodeXY(sample.zw, BDEF);	// up
	vec2 flow = (flux.zy - flux.xw) * 0.01;
	
	// generate on high-flow
	float flowgen = length(flow) / 1.5;
	float foam1 = texture2D(gm_BaseTexture, (v_vTexcoord * 50. + u_uFragTime * vec2(1.35, 1.15) ) ).a;
	float foam2 = texture2D(gm_BaseTexture, (v_vTexcoord * 10. + u_uFragTime * vec2(-2.25, -2.25) ) ).a;
	float foam = min(foam1, foam2) * flowgen * 0.75;
	//float foam = foam1 * flowgen * 0.75;
	gl_FragColor = vec4(vec3(1.0), foam);
}
