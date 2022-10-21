varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec3 u_uSize;	// (cellCount, cellSize, texSize)

#define BDEF 256.0

#define SLOT_HEIGHT		0.0
#define SLOT_DEPTH		1.0
#define SLOT_FLUX_LD	2.0
#define SLOT_FLUX_RU	3.0

precision highp float;

vec2 px = vec2(1.0) / u_uSize.z;

vec4 encodeRGBA(in float _f, float _bound) {
	float _half = 8388607.;
	float _val = floor(_f + 256.) + _half;
	vec4 _rgba = vec4(vec3(0.), 255.-floor(fract(abs(_f)) * 255. + .5) );
	_rgba.b = floor(_val / 65536.);
	_rgba.g = floor((_val - _rgba.b * 65536.) / 256.);
	_rgba.r = mod(_val, 256.);
	return _rgba / 255.;
}
float decodeRGBA(in vec4 _rgba, in float _bound) {
	vec4 _v = _rgba * 255.;
	float _half = 8388607.;
	float _val = _v.r + _v.g * 256. + _v.b * 65536.;
	float _int = (_val - _half - 256.);
	float _frac = (_int < 0.) ? (_v.a / 255.) : 1. - (_v.a / 255.);
	return _int + mod(_frac, 1.0);
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

float nodeSlot(vec2 _pos) {
	return floor(_pos.x / u_uSize.y) + floor(_pos.y / u_uSize.y) * u_uSize.x;
}
vec2 positionSlot(float _slot) {
	return vec2(mod(_slot, u_uSize.x) * u_uSize.y, floor(_slot / u_uSize.x) * u_uSize.y);
}
vec4 lookupSlot(in vec2 _uv, in float _slot) {
	vec2 _pos = _uv + positionSlot(_slot) / u_uSize.z;
	return texture2D(gm_BaseTexture, _pos);
}
vec2 offsetSlot(in vec2 _uv) {
	vec2 _bounds = vec2(u_uSize.y / u_uSize.z);// - px;
	float _x;
	float _y;
	_x = ( (_uv.x < 0.0) ? - _uv.x : ( (_uv.x > _bounds.x) ? _uv.x - _bounds.x : 0.0) );
	_y = ( (_uv.y < 0.0) ? - _uv.y : ( (_uv.y > _bounds.y) ? _uv.y - _bounds.y : 0.0) );
	return vec2(_x, _y);
}

float readHeight(in vec2 _uv) {
	_uv = clamp(_uv, 0.0, u_uSize.y / u_uSize.z);
	return max(decodeRGBA(lookupSlot(_uv, 0.0), BDEF), 0.0);
}
float readDepth(in vec2 _uv) {
	_uv = clamp(_uv, 0.0, u_uSize.y / u_uSize.z);
	return max(decodeRGBA(lookupSlot(_uv, 1.0), BDEF), 0.0);
}
vec4 readFlux(in vec2 _uv) {
	//if (!inboundSlot(_uv)) return vec4(0.0);
	vec2 _offset = offsetSlot(_uv);
	if (length(_offset) > 0.0) return vec4(0.0);
	vec4 _flux;
	vec4 _embed;
	_embed = lookupSlot(_uv, 2.0);
	_flux.xy = vec2(decodeXY(_embed.xy, BDEF), decodeXY(_embed.zw, BDEF));
	_embed = lookupSlot(_uv, 3.0);
	_flux.zw = vec2(decodeXY(_embed.xy, BDEF), decodeXY(_embed.zw, BDEF));
	// protect from overflux during separate passes
	float _wdepth = decodeRGBA(lookupSlot(_uv, 1.0), BDEF);
	float _ftotal = _flux.x + _flux.y + _flux.z + _flux.w;
	return _flux * clamp(_wdepth / _ftotal, 0.0, 1.0);
	return _flux;
}

void main() {
	vec2 texpos = floor(v_vTexcoord * u_uSize.z);
	float slot = nodeSlot(texpos);
	vec2 uvs = v_vTexcoord - positionSlot(slot)/u_uSize.z;
	
	vec4 pack = lookupSlot(uvs, slot);
	
	// update depth
	if (slot == SLOT_DEPTH) {
		float depth = readDepth(uvs);
		vec4 myflux = readFlux(uvs);
		float myfluxtotal = myflux.x + myflux.y + myflux.z + myflux.w;
		float influx = 0.0;
		influx += readFlux(uvs + vec2(px.x, 0.0)).x;
		influx += readFlux(uvs + vec2(0.0, px.y)).w;
		influx += readFlux(uvs + vec2(-px.x, 0.0)).z;
		influx += readFlux(uvs + vec2(0.0, -px.y)).y;
		depth = depth - myfluxtotal + influx;
		pack = encodeRGBA(max(depth, 0.0), BDEF);
	}
	
    gl_FragColor = pack;
}
