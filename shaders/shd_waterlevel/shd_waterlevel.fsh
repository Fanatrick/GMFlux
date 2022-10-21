varying vec2 v_vTexcoord;
varying vec3 v_vWorldPos;
varying float v_vWaterLevel;
varying vec3 v_vNormal;
varying vec2 v_vScreenpos;
varying float v_vDepth;
varying vec3 v_vLookat;
varying float v_vOOB;

uniform vec4 u_uWaterColBegin;
uniform vec4 u_uWaterColEnd;
uniform vec3 u_uReflectionRange;	// (start_alpha, end_alpha, z_falloff)

uniform float u_uWaterColFalloff;

uniform float u_uDepthFalloff;

uniform vec3 u_uSunray;

float decodeRGBA(in vec4 _rgba, in float _bound) {
	vec4 _v = _rgba * 255.;
	float _half = 8388607.;
	float _val = _v.r + _v.g * 256. + _v.b * 65536.;
	float _int = (_val - _half - 256.);
	float _frac = (_int < 0.) ? (_v.a / 255.) : 1. - (_v.a / 255.);
	return _int + mod(_frac, 1.0);
}

// credit @XorDev
vec3 sky(vec3 pos) {
	#define PI 3.14159265358979
	vec4 uvs = vec4(0.0, 0.67, 1.0, 0.33);
	vec2 u = vec2(atan(pos.x,pos.y)/2.,-asin( abs(pos.z) ))/PI+.5;
	vec3 t = texture2D(gm_BaseTexture, u * uvs.zw + uvs.xy).rgb;
	
	return t;
}

float lum(vec3 col) {
	return (0.2126*col.r + 0.7152*col.g + 0.0722*col.b);
}

void main() {
	if (v_vOOB < 0.1) discard;
	if (floor(v_vWaterLevel) < 1.0) discard;
	
	vec3 norm = normalize(v_vNormal);
	vec3 sunray = normalize(u_uSunray);
	
	float light = abs(dot(sunray, norm));
	light = pow(light, 4.0);
	
	float fog = min(v_vWorldPos.z/32000., 1.0);
	fog = 1.0 - pow(fog, 8.);
	
	norm = normalize(vec3(norm.xy, norm.z * 2.5));
	vec2 flookup = v_vScreenpos.xy * vec2(1.0, 0.334) + norm.xy*0.02;
	flookup.x = clamp(flookup.x, 0.0, 1.0);
	flookup.y = clamp(flookup.y, 0.0, 0.333);
	gl_FragColor.xyz = texture2D(gm_BaseTexture, flookup ).xyz;
	
	flookup = vec2(0.0, 0.334) + v_vScreenpos.xy * vec2(1.0, 0.333);
	flookup.x = clamp(flookup.x, 0.0, 1.0);
	flookup.y = clamp(flookup.y, 0.334, 0.666);
	float bdepth = decodeRGBA(texture2D(gm_BaseTexture, flookup ), 256.0);
	bdepth = max(bdepth - v_vDepth - 1.0, 0.0);
	
	vec4 waterColor = mix(u_uWaterColBegin, u_uWaterColEnd, min(bdepth * u_uWaterColFalloff, 1.0) );
	
	float alp = waterColor.a;
	
	alp = min(bdepth / 80.0, 1.0);
	
	gl_FragColor.xyz = mix(gl_FragColor.xyz, waterColor.xyz, waterColor.a);
	gl_FragColor.xyz *= mix(vec3(1.0), waterColor.xyz, min(bdepth * u_uDepthFalloff, 1.0) );
	
	gl_FragColor.xyz += light * 0.25; 
	
	// apply reflection
	vec3 vray = normalize(v_vLookat);
	vec3 vnor = normalize(vec3(norm.xy, norm.z));
	vec3 refl = sky(reflect(vray, vnor));
	gl_FragColor.xyz = mix(gl_FragColor.xyz, refl, clamp(v_vDepth / u_uReflectionRange.z * (1.+lum(refl)*2.0), u_uReflectionRange.x, u_uReflectionRange.y));
	
	// apply shallow foam/wetness
	float shore = min(bdepth / 80.0, 1.0);
	gl_FragColor.xyz = mix(vec3(mix(0.0, 1.0, min(bdepth / 80.0, 1.0))), gl_FragColor.xyz, shore * shore );
	
	gl_FragColor.a = alp * fog;
}
