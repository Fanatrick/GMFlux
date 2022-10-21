varying vec2 v_vTexcoord;
varying vec3 v_vWorldPos;
varying float v_vOOB;

void main() {
	if (v_vOOB <= 0.1) discard;
	float fog = min(v_vWorldPos.z/32000., 1.0);
	gl_FragColor = texture2D( gm_BaseTexture, v_vWorldPos.xy / 2560., v_vWorldPos.z / 32000. );
	gl_FragColor.a = 1.0 - pow(fog, 16.);
}
