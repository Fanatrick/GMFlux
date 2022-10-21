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
float rand(vec2 co) {
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
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
	
	// tiny rotator offset
	vec2 frot = vec2(sin(length(flow)), cos(length(flow))) * 0.19 * rand(v_vTexcoord * u_uFragTime * vec2(451.23, 94.526));
	// velocity
	float veloc = (0.25 + rand(u_uFragTime * vec2(160.81, 380.34) * v_vTexcoord) * 1.25 ) * 0.001 * 0.6;
	sample = texture2D(gm_BaseTexture, v_vTexcoord - (flow - frot) * veloc);
	
	// mandatory falloff
	float foam = sample.a - 1.0 / 255.0;
	
	// flow falloff
	foam -= (flux.x + flux.y + flux.z + flux.w) / 4500.0;
	
	gl_FragColor = vec4(sample.rgb, foam);
}
