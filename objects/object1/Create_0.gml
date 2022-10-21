quality = 2; // 0 - low, 1 - medium, 2 - high, 3 - benchmark
wiretoggle = 0;
raintoggle = 0;
brushsize = 2;
instructoggle = 0;

// World dimensions
worldxlen = 65536*2;
worldylen = 65536*2;
worldzlen = 2048*4;

// flux resolution
fluxsize = 1024*(power(2, quality));

// create a new flux container
container = new GMFlux_container(fluxsize);
container.surfaceEnsure();
container.cellEncodeHeightSprite(FluxCell.Height, hmap, 0, worldzlen);	// encode heightmap with worldzlen units of max height
container.cellEncodeFill(FluxCell.Depth, 200);	// fill initial water level
container.cellEncodeFillXY(FluxCell.FluxLD, 0.0, 0.0);	// init 0 cardinal flux
container.cellEncodeFillXY(FluxCell.FluxRU, 0.0, 0.0);
container.lookupAlloc(4);	// allocate 4 fragment lookups

// place player at center
x = worldxlen/2;
y = worldylen/2;
z = -1000;

// handle camera
pitch = 0;
yaw = -45;

xto = x + dcos(yaw);
yto = y - dsin(yaw);
zto = z - dsin(pitch);

camera = camera_create();
camera_set_view_mat(camera, matrix_build_lookat(x, y, z, xto, yto, zto, 0, 0, -1));
camera_set_proj_mat(camera, matrix_build_projection_perspective_fov(60, window_get_width() / window_get_height(), 1, 32000));
camera_apply(camera);

// output buffer from height
//heightbuffer = container.cellOutputBuffer(FluxCell.Height);

// frag lookup getZ example method
getZ = function() {
	var _e = container.lookupReadIndex(0);
	return (-container.decodeRGBA(_e[0], _e[1], _e[2], _e[3]));
}

// create heightfield vertex format
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_texcoord();
vformat = vertex_format_end();

#region @OLD create heightfield vertex buffer
//vwidth = 500;
//vheight = 500;
//vbuffer = vertex_create_buffer();
//vertex_begin(vbuffer, vformat);
// ---------------------------- //
// trianglelist linear
/*for(var j = -vwidth/2; j < vwidth/2-1; j ++) {
	for(var i = -vheight/2; i < vheight/2-1; i ++) {
		vertex_position_3d(vbuffer, i, j, 0);
		vertex_texcoord(vbuffer, 0, 0);
		vertex_position_3d(vbuffer, i+1, j, 0);
		vertex_texcoord(vbuffer, 1, 0);
		vertex_position_3d(vbuffer, i, j+1, 0);
		vertex_texcoord(vbuffer, 0, 1);
		
		vertex_position_3d(vbuffer, i+1, j, 0);
		vertex_texcoord(vbuffer, 1, 0);
		vertex_position_3d(vbuffer, i, j+1, 0);
		vertex_texcoord(vbuffer, 0, 1);
		vertex_position_3d(vbuffer, i+1, j+1, 0);
		vertex_texcoord(vbuffer, 1, 1);
	}
}*/
// ---------------------------- //
// trianglelist optimized
/*
var _rangex = vwidth/2,
	_rangey = vheight/2;
for(var j = -_rangey; j < _rangey-1; j ++) {
	for(var i = -_rangex; i < _rangex-1; i ++) {
		var _lod1 = clamp(ceil(max(abs(i), abs(j)) / 32), 1, 1),
			_lod2 = clamp(ceil(max(abs(i+1), abs(j)) / 32), 1, 1),
			_lod3 = clamp(ceil(max(abs(i), abs(j+1)) / 32), 1, 1),
			_lod4 = clamp(ceil(max(abs(i+1), abs(j+1)) / 32), 1, 1);
			
		var _vi1 = i * _lod1,
			_vj1 = j * _lod1,
			_vi2 = (i+1) * _lod1,
			_vj2 = (j+1) * _lod1;
		
		vertex_position_3d(vbuffer, _vi1, _vj1, 0);
		vertex_texcoord(vbuffer, 0, 0);
		vertex_position_3d(vbuffer, _vi2, _vj1, 0);
		vertex_texcoord(vbuffer, 1, 0);
		vertex_position_3d(vbuffer, _vi1, _vj2, 0);
		vertex_texcoord(vbuffer, 0, 1);
		
		vertex_position_3d(vbuffer, _vi2, _vj1, 0);
		vertex_texcoord(vbuffer, 1, 0);
		vertex_position_3d(vbuffer, _vi1, _vj2, 0);
		vertex_texcoord(vbuffer, 0, 1);
		vertex_position_3d(vbuffer, _vi2, _vj2, 0);
		vertex_texcoord(vbuffer, 1, 1);
	}
}*/
// ---------------------------- //
// trianglestrip
/*for(var j = 0; j <= vheight; j ++) {
	if !(j mod 2) {
		for(var i = 0; i <= vwidth; i ++) {
			vertex_position_3d(vbuffer, i, j, 0);
			vertex_texcoord(vbuffer, i, j);
			vertex_position_3d(vbuffer, i, j+1, 0);
			vertex_texcoord(vbuffer, i, j);
		}
	}	else	{
		for(var i = vwidth; i >= 0; i --) {
			vertex_position_3d(vbuffer, i, j, 0);
			vertex_texcoord(vbuffer, i, j);
			vertex_position_3d(vbuffer, i, j+1, 0);
			vertex_texcoord(vbuffer, i, j);
		}
	}
}*/
//vertex_end(vbuffer);
//vertex_freeze(vbuffer);
#endregion

// create example render targets
fbuffer = surface_create(room_width, room_height);		// framebuffer
zbuffer = surface_create(room_width, room_height);		// zbuffer
rbuffer = surface_create(room_width, room_height * 3);	// fbuffer + zbuffer + skybox
advectSize = 1024*(power(2, quality));
abuffer = surface_create(advectSize, advectSize);		// advection buffer
abuffer_pong = surface_create(advectSize, advectSize);	// advection swap buffer

// ---------------------------- //
// lod mesh
lodmesh = new GMFlux_lodNode();		// create starting lodmesh node
var _func_lod = function() {
	if (depth == 0) {
		x = -32768;
		y = -32768;
		w = 32768 * 2;
		h = 32768 * 2;
		cx = 0;
		cy = 0;
	}	else	{
		w = parent.w / 2;
		h = parent.h / 2;
		x = parent.x + w * (quadrant % 2);
		y = parent.y + h * (quadrant div 2);
		cx = x + (w / 2);
		cy = y + (h / 2);
	}
	var _lodmin = 6,
		_lodmax = (Object1.quality < 2) ? 8 : 9,
		_loddist = 32768*4;
	var qx = x + w * .5,
		qy = y + h * .5;
	var _lod = clamp(_lodmax - (sqrt(qx * qx + qy * qy)) / _loddist * _lodmax, _lodmin, _lodmax);
	if (_lod > depth) openAll();
}
lodmesh.propagate(_func_lod);		// propagates breadth-first

vbuffer = vertex_create_buffer();	// create vbuffer from lodmesh
vertex_begin(vbuffer, vformat);
var _func_build = function() {
	var _tris = __flagtrianglelut[edgeFlags],
		_len = array_length(_tris);
	for(var i = 0; i < _len; i ++) {
		var _tri = _tris[i];
		var _vert1 = _tri[0],
			_vert2 = _tri[1];
		vertex_position_3d(	Object1.vbuffer, cx + _vert1[0] * w / 2, cy + _vert1[1] * h / 2, 0);
		vertex_texcoord(	Object1.vbuffer, 0.5 + _vert1[0]/2, 0.5 + _vert1[1]/2);
		vertex_position_3d(	Object1.vbuffer, cx + _vert2[0] * w / 2, cy + _vert2[1] * h / 2, 0);
		vertex_texcoord(	Object1.vbuffer, 0.5 + _vert2[0]/2, 0.5 + _vert2[1]/2);
		vertex_position_3d(	Object1.vbuffer, cx, cy, 0);
		vertex_texcoord(	Object1.vbuffer, 0.5, 0.5);
	}
}
lodmesh.propagate(_func_build);
vertex_end(vbuffer);
vertex_freeze(vbuffer);

// quick noncubemap skybox,
// credit: @XorDev
vertex_format_begin();
vertex_format_add_position_3d();
buf_format = vertex_format_end();
buf_sky = vertex_create_buffer();
vertex_begin(buf_sky, buf_format);
var _s = 8000;
//-X
vertex_position_3d(buf_sky,-_s,-_s,+_s);
vertex_position_3d(buf_sky,-_s,-_s,-_s);
vertex_position_3d(buf_sky,-_s,+_s,-_s);
vertex_position_3d(buf_sky,-_s,+_s,+_s);
vertex_position_3d(buf_sky,-_s,-_s,+_s);
vertex_position_3d(buf_sky,-_s,+_s,-_s);

//+X
vertex_position_3d(buf_sky,+_s,-_s,-_s);
vertex_position_3d(buf_sky,+_s,-_s,+_s);
vertex_position_3d(buf_sky,+_s,+_s,-_s);
vertex_position_3d(buf_sky,+_s,-_s,+_s);
vertex_position_3d(buf_sky,+_s,+_s,+_s);
vertex_position_3d(buf_sky,+_s,+_s,-_s);

//-Y
vertex_position_3d(buf_sky,-_s,-_s,-_s);
vertex_position_3d(buf_sky,-_s,-_s,+_s);
vertex_position_3d(buf_sky,+_s,-_s,-_s);
vertex_position_3d(buf_sky,-_s,-_s,+_s);
vertex_position_3d(buf_sky,+_s,-_s,+_s);
vertex_position_3d(buf_sky,+_s,-_s,-_s);

//+Y
vertex_position_3d(buf_sky,-_s,+_s,+_s);
vertex_position_3d(buf_sky,-_s,+_s,-_s);
vertex_position_3d(buf_sky,+_s,+_s,-_s);
vertex_position_3d(buf_sky,+_s,+_s,+_s);
vertex_position_3d(buf_sky,-_s,+_s,+_s);
vertex_position_3d(buf_sky,+_s,+_s,-_s);

//-Z
vertex_position_3d(buf_sky,-_s,-_s,-_s);
vertex_position_3d(buf_sky,+_s,-_s,-_s);
vertex_position_3d(buf_sky,-_s,+_s,-_s);
vertex_position_3d(buf_sky,+_s,-_s,-_s);
vertex_position_3d(buf_sky,+_s,+_s,-_s);
vertex_position_3d(buf_sky,-_s,+_s,-_s);

//+Z
vertex_position_3d(buf_sky,+_s,-_s,+_s);
vertex_position_3d(buf_sky,-_s,-_s,+_s);
vertex_position_3d(buf_sky,-_s,+_s,+_s);
vertex_position_3d(buf_sky,+_s,+_s,+_s);
vertex_position_3d(buf_sky,+_s,-_s,+_s);
vertex_position_3d(buf_sky,-_s,+_s,+_s);

vertex_end(buf_sky);
vertex_freeze(buf_sky);
