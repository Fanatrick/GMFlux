attribute vec3 in_Position;                  // (x,y,z)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying float v_vDepth;
varying float v_vOOB;

uniform sampler2D u_uSampler;
uniform vec4 u_uSamplerUVs;
uniform vec3 u_uWorldSize;

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

float sampleHeight(in vec2 _pos, in sampler2D _heightmap) {
	vec4 _sample = texture2D(_heightmap, _pos);
	return decodeRGBA(_sample, 256.);
}

bool inbounds(in vec2 _wpos) {
	return all(greaterThan(vec4(_wpos, u_uWRegion.zw), vec4(u_uWRegion.xy, _wpos)));
}

void main() {
	vec3 spos = vec3(u_uPosition + in_Position.xy * u_uScale, 0.0);
	spos.z = -sampleHeight(u_uSamplerUVs.xy + clamp(spos.xy / u_uWorldSize.xy, 0.0, 1.0) * (u_uSamplerUVs.zw - u_uSamplerUVs.xy), u_uSampler);
    vec4 object_space_pos = vec4(spos, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vTexcoord = in_TextureCoord;
	v_vDepth = gl_Position.z;
	v_vOOB = float(inbounds(spos.xy));
}
