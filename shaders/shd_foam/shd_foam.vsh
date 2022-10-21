attribute vec3 in_Position;                  // (x,y,z)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec3 v_vWorldPos;
varying float v_vWaterLevel;
varying float v_vOOB;

uniform sampler2D u_uSampler;
uniform vec2 u_uSamplerSize;
uniform vec4 u_uSamplerUVs;
uniform vec3 u_uWorldSize;
uniform vec4 u_uWaterUVs;

uniform vec2 u_uPosition;
uniform vec2 u_uScale;
uniform vec4 u_uWRegion;

float decodeRGBA(in vec4 _rgba, in float _bound) {
	vec4 _v = _rgba * 255.;
	float _half = 8388607.;
	float _val = _v.r + _v.g * 256. + _v.b * 65536.;
	float _int = (_val - _half - 256.);
	float _frac = (_int < 0.) ? (_v.a / 255.) : 1. - (_v.a / 255.);
	return _int + mod(_frac, 1.0);
}

float sampleHeight(in vec2 _pos) {
	vec4 _sample = texture2D(u_uSampler, _pos);
	return decodeRGBA(_sample, 256.);
}

bool inbounds(in vec2 _wpos) {
	return all(greaterThan(vec4(_wpos, u_uWRegion.zw), vec4(u_uWRegion.xy, _wpos)));
}

void main() {
	vec3 spos = vec3(u_uPosition + in_Position.xy * u_uScale, 0.0);
	
	float height = -sampleHeight(u_uSamplerUVs.xy + clamp(spos.xy / u_uWorldSize.xy, 0.0, 1.0) * (u_uSamplerUVs.zw - u_uSamplerUVs.xy) );
	float water = -sampleHeight(u_uWaterUVs.xy + clamp(spos.xy / u_uWorldSize.xy, 0.0, 1.0) * (u_uWaterUVs.zw - u_uWaterUVs.xy) );
	
	spos.z = height + water;
	
    vec4 object_space_pos = vec4(spos, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
	
	v_vWorldPos = gl_Position.xyz;
	gl_Position.z -= 0.08;
    v_vTexcoord = spos.xy / u_uWorldSize.xy;
	v_vWaterLevel = (-water);
	v_vOOB = float(inbounds(spos.xy));
}
