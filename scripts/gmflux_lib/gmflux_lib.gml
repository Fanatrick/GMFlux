enum FluxCell {
	Height,		// Height.rgba
	Depth,		// Depth.rgba
	FluxLD,		// FluxLeft.rg,		FluxDown.ba (This assignment is a little bit on the stupid side)
	FluxRU		// FluxRight.rg,	FluxUp.ba
}

function GMFlux_container(_tsize = 4096) constructor {
/// @func			GMFlux_container([texsize = 4096])
/// @description	constructs a flux simulation container object
	fluxStrength = 0.250;
	fluxAtten = 0.975;
	fluxSpill = 0.0;
	
	texSize = _tsize;
	texSubCount = 2;
	texTotalCount = texSubCount * texSubCount;
	cellSize = texSize div texSubCount; 
	
	fluxSurface = -1;
	pongSurface = -1;
	stitchSurface = -1;
	
	fluxSnapshot = -1;
	pongSnapshot = -1;
	stitchSnapshot = -1;
	
	surfaceSafeTimer = 0;
	snapshotSafeTimer = 0;
	
	cellActive = -1;
	cellActiveX = 0;
	cellActiveY = 0;
	
	static cellGetX = function(_fluxCell)	{	return (_fluxCell mod texSubCount) * cellSize	}
	static cellGetY = function(_fluxCell)	{	return (_fluxCell div texSubCount) * cellSize	}
	static cellGetX2 = function(_fluxCell)	{	return (_fluxCell mod texSubCount) * cellSize + cellSize	}
	static cellGetY2 = function(_fluxCell)	{	return (_fluxCell div texSubCount) * cellSize + cellSize	}
	
	static surfaceEnsure = function() {
	/// @func			surfaceEnsure()
	/// @description	ensure render targets exist
		if (!surface_exists(fluxSurface)) {
			fluxSurface = surface_create(texSize, texSize);
			surfaceSafeTimer = 0;
		}
		if (!surface_exists(pongSurface)) {
			pongSurface = surface_create(texSize, texSize);
			surfaceSafeTimer = 0;
		}
		if (!surface_exists(stitchSurface)) {
			stitchSurface = surface_create(texSize, 8 * texTotalCount);
			surfaceSafeTimer = 0;
		}
	}
	static surfacePing = function() {
	/// @func			surfacePing()
	/// @description	copy to pong
		gpu_push_state();
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		surface_set_target(pongSurface);
		draw_surface(fluxSurface, 0, 0);
		surface_reset_target();
		gpu_pop_state();
	}
	static surfaceFree = function() {
	/// @func			surfaceFree()
	/// @description	free surfaces
		if (surface_exists(fluxSurface)) {
			surface_free(fluxSurface);
			fluxSurface = -1;
		}
		if (surface_exists(pongSurface)) {
			surface_free(pongSurface);
			pongSurface = -1;
		}
		if (surface_exists(stitchSurface)) {
			surface_free(stitchSurface);
			stitchSurface = -1;
		}
	}
	
	static surfaceSnapshotEnsure = function() {
	/// @func			surfaceEnsure()
	/// @description	ensure ram snapshots exist
		if (fluxSnapshot == -1) {
			fluxSnapshot = buffer_create(texSize * texSize * 4, buffer_fast, 1);
			snapshotSafeTimer = 0;
		}
		if (pongSnapshot == -1) {
			pongSnapshot = buffer_create(texSize * texSize * 4, buffer_fast, 1);
			snapshotSafeTimer = 0;
		}
		if (stitchSnapshot == -1) {
			stitchSnapshot = buffer_create(texSize * texSize * 4, buffer_fast, 1);
			snapshotSafeTimer = 0;
		}
	}
	static surfaceSnapshotWrite = function() {
	/// @func			surfaceSnapshotWrite()
	/// @description	write vram snapshot to ram
		surfaceEnsure();
		surfaceSnapshotEnsure();
		if (surfaceSafeTimer <= 1) return false;
		if (snapshotSafeTimer <= 1) return false;
		buffer_get_surface(fluxSnapshot, fluxSurface, 0);
		buffer_get_surface(pongSnapshot, pongSurface, 0);
		buffer_get_surface(stitchSnapshot, stitchSurface, 0);
		return true;
	}
	static surfaceSnapshotRead = function() {
	/// @func			surfaceSnapshotWrite()
	/// @description	write vram snapshot to ram
		surfaceEnsure();
		surfaceSnapshotEnsure();
		if (surfaceSafeTimer <= 1) return false;
		if (snapshotSafeTimer <= 1) return false;
		buffer_set_surface(fluxSnapshot, fluxSurface, 0);
		buffer_set_surface(pongSnapshot, pongSurface, 0);
		buffer_set_surface(stitchSnapshot, stitchSurface, 0);
		return true;
	}
	static surfaceSnapshotFree = function() {
	/// @func			surfaceSnapshotFree()
	/// @description	free snapshots
		if (fluxSnapshot != -1) {
			fluxSnapshot = buffer_delete(fluxSnapshot);
			snapshotSafeTimer = 0;
		}
		if (pongSnapshot != -1) {
			pongSnapshot = buffer_delete(pongSnapshot);
			snapshotSafeTimer = 0;
		}
		if (stitchSnapshot != -1) {
			stitchSnapshot = buffer_delete(stitchSnapshot);
			snapshotSafeTimer = 0;
		}
	}
	
	static cellEncodeHeightSprite = function(_fluxCell, _spr, _img, _factor) {
	/// @func			cellEncodeHeightSprite(FluxCell, sprite_index, image_index, height_max)
	/// @description	encodes a sprite resource into a cell
		var _x = (_fluxCell mod texSubCount) * cellSize,
			_y = (_fluxCell div texSubCount) * cellSize;
		gpu_push_state();
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		surface_set_target(fluxSurface);
		var _shader = GMFluxShd_encodeHeightfield;
		shader_set(_shader);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uHeightFactor"), _factor);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uTexSize"), sprite_get_width(_spr), sprite_get_height(_spr));
		draw_sprite_stretched(_spr, _img, _x, _y, cellSize, cellSize);
		shader_reset();
		surface_reset_target();
		gpu_pop_state();
	}
	static cellEncodeHeightSurface = function(_fluxCell, _surf, _factor) {
	/// @func			cellEncodeHeightSurface(FluxCell, surface_index, height_max)
	/// @description	encodes a surface into a cell
		var _x = (_fluxCell mod texSubCount) * cellSize,
			_y = (_fluxCell div texSubCount) * cellSize;
		gpu_push_state();
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		surface_set_target(fluxSurface);
		var _shader = GMFluxShd_encodeHeightfield;
		shader_set(_shader);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uHeightFactor"), _factor);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uTexSize"), surface_get_width(_surf), surface_get_height(_surf));
		draw_surface_stretched(_surf, _x, _y, cellSize, cellSize);
		shader_reset();
		surface_reset_target();
		gpu_pop_state();
	}
	static cellEncodeFill = function(_fluxCell, _value) {
	/// @func			cellEncodeFill(FluxCell, value)
	/// @description	fills a cell with a value
		var _x = (_fluxCell mod texSubCount) * cellSize,
			_y = (_fluxCell div texSubCount) * cellSize;
		gpu_push_state();
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		surface_set_target(fluxSurface);
		var _shader = GMFluxShd_encodeFill;
		shader_set(_shader);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uValue"), _value);
		draw_sprite_stretched(GMFluxSpr_2x2, 0, _x, _y, cellSize, cellSize);
		shader_reset();
		surface_reset_target();
		gpu_pop_state();
	}
	static cellEncodeFillXY = function(_fluxCell, _valueX, _valueY) {
	/// @func			cellEncodeFill(FluxCell, value_x, value_y)
	/// @description	fills a cell with a 2 component vector value
		var _x = (_fluxCell mod texSubCount) * cellSize,
			_y = (_fluxCell div texSubCount) * cellSize;
		gpu_push_state();
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		surface_set_target(fluxSurface);
		var _shader = GMFluxShd_encodeFillXY;
		shader_set(_shader);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uValue"), _valueX, _valueY);
		draw_sprite_stretched(GMFluxSpr_2x2, 0, _x, _y, cellSize, cellSize);
		shader_reset();
		surface_reset_target();
		gpu_pop_state();
	}
	
	static cellAddBegin = function(_fluxCell, _shader = GMFluxShd_additive) {
	/// @func			cellAddBegin(FluxCell, [shader_index = GMFluxShd_additive])
	/// @description	begin writing to a cell
		surfacePing();
		cellActive = _fluxCell;
		cellActiveX = (_fluxCell mod texSubCount) * cellSize;
		cellActiveY = (_fluxCell div texSubCount) * cellSize
		gpu_push_state();
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		surface_set_target(fluxSurface);
		shader_set(_shader);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uSize"), texSubCount, cellSize, texSize);
		texture_set_stage(shader_get_sampler_index(_shader, "u_uSampler"), surface_get_texture(pongSurface));
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uStencil"), 0, 0, cellSize, cellSize);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uStencilOffset"), cellActiveX, cellActiveY);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uRange"), 0.0, 1.0);
		
		matrix_set(matrix_world, matrix_build(cellActiveX, cellActiveY, 0, 0, 0, 0, 1, 1, 1));
	}
	static cellAddXYBegin = function(_fluxCell, _component) {
	/// @func			cellAddXYBegin(FluxCell, component)
	/// @description	begin writing single component of a vec2 to a cell
		cellAddBegin(_fluxCell, GMFluxShd_additiveXY);
		shader_set_uniform_i(shader_get_uniform(GMFluxShd_additiveXY, "u_uComponent"), _component);
	}
	static cellAddSetRange = function(_min, _max) {
	/// @func			cellAddSetRange(value_min, value_max)
	/// @description	set the range of current cell write operation
		shader_set_uniform_f(shader_get_uniform(shader_current(), "u_uRange"), _min, _max);
	}
	static cellAddEnd = function() {
	/// @func			cellAddEnd()
	/// @description	finish writing to a cell
		cellActive = -1;
		shader_reset();
		surface_reset_target();
		gpu_pop_state();
		matrix_set(matrix_world, matrix_stack_top());
	}
	
	static cellOutputSurface = function(_fluxCell) {
	/// @func			cellOutputSurface(FluxCell)
	/// @description	output cell to a surface
		var _surf = surface_create(cellSize, cellSize);
		var _cx = cellGetX(_fluxCell),
			_cy = cellGetY(_fluxCell);
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		surface_set_target(_surf);
		draw_surface(fluxSurface, -_cx, -_cy);
		surface_reset_target();
		gpu_set_blendmode(bm_normal);
		return _surf;
	}
	static cellOutputBuffer = function(_fluxCell) {
	/// @func			cellOutputBuffer(FluxCell)
	/// @description	output cell to a buffer
		var _surf = cellOutputSurface(_fluxCell);
		var _buff = buffer_create(cellSize * cellSize * 4, buffer_fast, 1);
		buffer_get_surface(_buff, _surf, 0);
		surface_free(_surf);
		return _buff;
	}
	
	static stepFlux = function() {
	/// @func			stepFlux()
	/// @description	perform a step of flux simulation
		gpu_push_state();
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		surface_set_target(pongSurface);
		var _shader = GMFluxShd_stepFlux;
		shader_set(_shader);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uSize"), texSubCount, cellSize, texSize);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uStrength"), fluxStrength);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uAttenuation"), fluxAtten);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uSpill"), fluxSpill);
		draw_surface(fluxSurface, 0, 0);
		shader_reset();
		surface_reset_target();
		var _temp = pongSurface;
		pongSurface = fluxSurface;
		fluxSurface = _temp;
		gpu_pop_state();
	}
	static stepDepth = function() {
	/// @func			stepDepth(FluxCell)
	/// @description	perform a step of depth simulation
		gpu_push_state();
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		surface_set_target(pongSurface);
		var _shader = GMFluxShd_stepDepth;
		shader_set(_shader);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uSize"), texSubCount, cellSize, texSize);
		draw_surface(fluxSurface, 0, 0);
		shader_reset();
		surface_reset_target();
		var _temp = pongSurface;
		pongSurface = fluxSurface;
		fluxSurface = _temp;
		gpu_pop_state();
	}
	
	//------------------------------------------------------------//
	// Lookups
	static __lookupVFormatCreate = function() {
		vertex_format_begin();
		vertex_format_add_position_3d();	// lookup_id, none
		return vertex_format_end();
	}
	
	static lookupVFormat = __lookupVFormatCreate();
	lookupBuffer = -1;
	lookupSurface = -1;
	lookupModel = -1;
	lookupSize = 0;
	
	static lookupAlloc = function(_size) {
	/// @func			lookupAlloc(size)
	/// @description	allocate n lookup fragments
		lookupFree();
		var _sa = power(2, ceil(log2(sqrt(_size))) ),
			_sb = power(2, ceil(log2(_size)) );
		lookupSurface = (_sb > 4) ? surface_create(_sa, _sa) : surface_create(_sb, 1);
		lookupBuffer = buffer_create(_size * 4, buffer_fast, 1);
		lookupModel = vertex_create_buffer();
		vertex_begin(lookupModel, lookupVFormat);
		for(var i = 0; i < _size; i ++) {
			vertex_position_3d(lookupModel, i, 0, 0);
		}
		vertex_end(lookupModel);
		vertex_freeze(lookupModel);
		lookupSize = _size;
	}
	static lookupFree = function() {
	/// @func			lookupFree()
	/// @description	free allocated lookup mem
		if surface_exists(lookupSurface) {
			surface_free(lookupSurface);
			lookupSurface = -1;
		}
		if buffer_exists(lookupBuffer) {
			buffer_delete(lookupBuffer);
			lookupBuffer = -1;
		}
		if (lookupModel != -1) {
			vertex_delete_buffer(lookupModel);
			lookupModel = -1;
		}
	}
	static lookupIdFromPosition = function(_x, _y) {
	/// @func			lookupIdFromPosition(x, y)
	/// @description	get lookup id from flux coordinates
		return (_x + _y * cellSize);
	}
	static lookupWrite = function(_cells, _ids, _offset = 0) {
	/// @func			lookupWrite(array_cells, array_ids, [offset = 0])
	/// @description	write fragments to allocated lookup mem
		var _shader = GMFluxShd_lookup;
		gpu_push_state();
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		gpu_set_tex_filter(false);
		shader_set(_shader);
		surface_set_target(lookupSurface);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uSize"), texSubCount, cellSize, texSize);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uSizePass"), surface_get_width(lookupSurface), surface_get_height(lookupSurface));
		shader_set_uniform_f_array(shader_get_uniform(_shader, "u_uListCells"), _cells);
		shader_set_uniform_f_array(shader_get_uniform(_shader, "u_uListIds"), _ids);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uListOffset"), _offset);
		vertex_submit(lookupModel, pr_pointlist, surface_get_texture(fluxSurface) );
		shader_reset();
		surface_reset_target();
		gpu_pop_state();
	}
	static lookupCopy = function() {
	/// @func			lookupCopy()
	/// @description	copy lookup mem to ram
		buffer_get_surface(lookupBuffer, lookupSurface, 0);
	}
	static lookupReadIndex = function(_index) {
	/// @func			lookupReadIndex(index)
	/// @description	output RGBA array of a frag at index from lookup mem
		var _r, _g, _b, _a;
		buffer_seek(lookupBuffer, buffer_seek_start, _index * 4);
		_r = buffer_read(lookupBuffer, buffer_u8);
		_g = buffer_read(lookupBuffer, buffer_u8);
		_b = buffer_read(lookupBuffer, buffer_u8);
		_a = buffer_read(lookupBuffer, buffer_u8);
		show_debug_message([_r, _g, _b, _a]);
		return [_r, _g, _b, _a];
	}
	
	//------------------------------------------------------------//
	// Encoding
	static encodeBound = 256;
	
	static encodeRGBA = function(_f, _bound = encodeBound) {
	/// @func encodeRGBA(float, [bound])
		var _half = 8388607,
			_val = floor(_f) + _half + 256;
		var _a = 255-round(frac(abs(_f)) * 255),
			_b = _val div 65536,
			_g = floor(_val - _b * 65536) div 256,
			_r = floor(_val) % 256;
		return [_r, _g, _b, _a];
	}
	static decodeRGBA = function(_r, _g, _b, _a, _bound = encodeBound) {
	/// @func decodeRGBA(r, g, b, a, [bound])
		var _val = _r + _g * 256 + _b * 65536,
			_half = 8388607,
			_int = (_val - _half - 256),
			_frac = _int < 0 ? (_a / 255) : 1 - (_a / 255);
		return _int + (_frac % 1.0);
	}
	static encodeXY = function(_f, _bound = encodeBound) {
	/// @func encodeXY(float, [bound])
		var _half = 32767,
			_val = _f * _bound + _half;
		var _y = _val div 256,
			_x = floor(_val) % 256;
		return [_x, _y];
	}
	static decodeXY = function(_x, _y, _bound = encodeBound) {
	/// @func decodeXY(x, y, [bound])
		var _val = _x + _y * 256,
			_half = 32767;
		return (_val - _half - 256.) / _bound;
	}
	
	//------------------------------------------------------------//
	// Destructor
	static free = function() {
	/// @func			free()
	/// @description	free everything and mark self for GC
		surfaceFree();
		surfaceSnapshotFree();
		lookupFree();
	}
}

	