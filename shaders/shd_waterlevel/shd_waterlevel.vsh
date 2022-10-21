attribute vec3 in_Position;                  // (x,y,z)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec3 v_vWorldPos;
varying float v_vWaterLevel;
varying vec3 v_vNormal;
varying vec2 v_vScreenpos;
varying float v_vDepth;
varying vec3 v_vLookat;
varying float v_vOOB;

uniform sampler2D u_uSampler;
uniform vec2 u_uSamplerSize;
uniform vec4 u_uSamplerUVs;
uniform vec3 u_uWorldSize;
uniform vec4 u_uWaterUVs;

uniform vec2 u_uPosition;
uniform vec2 u_uScale;

uniform float u_uVertexTime;
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

vec3 computeNormal(in vec2 _wpos) {
	vec3 off = vec3( vec2(1.0) / (u_uSamplerSize.xy), 0.0);
	vec2 _ppos = u_uWaterUVs.xy + clamp(_wpos.xy / u_uWorldSize.xy, 0.0, 1.0) * (u_uWaterUVs.zw - u_uWaterUVs.xy);
	float hL = sampleHeight(_ppos - off.xz);
	float hR = sampleHeight(_ppos + off.xz);
	float hD = sampleHeight(_ppos - off.zy);
	float hU = sampleHeight(_ppos + off.zy);
	_ppos = u_uSamplerUVs.xy + clamp(_wpos.xy / u_uWorldSize.xy, 0.0, 1.0) * (u_uSamplerUVs.zw - u_uSamplerUVs.xy);
	hL += sampleHeight(_ppos - off.xz);
	hR += sampleHeight(_ppos + off.xz);
	hD += sampleHeight(_ppos - off.zy);
	hU += sampleHeight(_ppos + off.zy);
	
	vec3 N;
	N.x = (hL - hR)*0.001;
	N.y = (hD - hU)*0.001;
	N.z = 2.0 / (u_uSamplerSize.x) * 128.0;
	return normalize(N);
}

bool inbounds(in vec2 _wpos) {
	return all(greaterThan(vec4(_wpos, u_uWRegion.zw), vec4(u_uWRegion.xy, _wpos)));
}

void main() {
	vec3 spos = vec3(u_uPosition + in_Position.xy * u_uScale, 0.0);
	v_vNormal = computeNormal(spos.xy);
	
	float height = -sampleHeight(u_uSamplerUVs.xy + clamp(spos.xy / u_uWorldSize.xy, 0.0, 1.0) * (u_uSamplerUVs.zw - u_uSamplerUVs.xy) );
	float water = -sampleHeight(u_uWaterUVs.xy + clamp(spos.xy / u_uWorldSize.xy, 0.0, 1.0) * (u_uWaterUVs.zw - u_uWaterUVs.xy) );
	
	spos.z = height + water;
	
	v_vWaterLevel = (-water);
	if (v_vWaterLevel < 1.0) spos.z += 100.;
	
    vec4 object_space_pos = vec4(spos, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
	
	v_vWorldPos = gl_Position.xyz;
	gl_Position.z -= 0.05;
    v_vTexcoord = in_TextureCoord;
	
	vec3 cam = (gm_Matrices[MATRIX_VIEW][3] * gm_Matrices[MATRIX_VIEW]).xyz;
	v_vLookat = spos.xyz + cam;
	
	v_vScreenpos = ( (gl_Position.xy/gl_Position.w) * .5 + .5);
	
	v_vDepth = gl_Position.z;
	
	v_vOOB = float(inbounds(spos.xy));
}
