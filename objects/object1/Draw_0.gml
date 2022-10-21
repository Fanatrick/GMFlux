
// controls
if keyboard_check_pressed(vk_enter) {
	wiretoggle ^= 1;
}
brushsize = clamp(brushsize + mouse_wheel_up() - mouse_wheel_down(), 2, 5);
var _brushscale = (brushsize < 5) ? (0.04 * power(2, brushsize)) * power(2, quality) : 128;

// add water
if keyboard_check(ord("1")) {
	container.cellAddBegin(FluxCell.Depth);
	container.cellAddSetRange(0.0, 100.0);
	var _spawnx = (x + dcos(yaw) * 2560*2) * (container.cellSize / worldxlen),
		_spawny = (y - dsin(yaw) * 2560*2) * (container.cellSize / worldylen);
	draw_sprite_ext(dropmap, 0, _spawnx, _spawny, _brushscale, _brushscale, 0, c_white, 1.0);
	container.cellAddEnd();
}
// subtract water
if keyboard_check(ord("2")) {
	container.cellAddBegin(FluxCell.Depth);
	container.cellAddSetRange(0.0, -100.0);
	var _spawnx = (x + dcos(yaw) * 2560*2) * (container.cellSize / worldxlen),
		_spawny = (y - dsin(yaw) * 2560*2) * (container.cellSize / worldylen);
	draw_sprite_ext(dropmap, 0, _spawnx, _spawny, _brushscale, _brushscale, 0, c_white, 1.0);
	container.cellAddEnd();
}
// add height
if keyboard_check(ord("3")) {
	container.cellAddBegin(FluxCell.Height);
	container.cellAddSetRange(0.0, 50.0);
	var _spawnx = (x + dcos(yaw) * 2560*2) * (container.cellSize / worldxlen),
		_spawny = (y - dsin(yaw) * 2560*2) * (container.cellSize / worldylen);
	draw_sprite_ext(dropmap, 0, _spawnx, _spawny, _brushscale, _brushscale, 0, c_white, 1.0);
	container.cellAddEnd();
}
// subtract height
if keyboard_check(ord("4")) {
	container.cellAddBegin(FluxCell.Height);
	container.cellAddSetRange(0.0, -50.0);
	var _spawnx = (x + dcos(yaw) * 2560*2) * (container.cellSize / worldxlen),
		_spawny = (y - dsin(yaw) * 2560*2) * (container.cellSize / worldylen);
	draw_sprite_ext(dropmap, 0, _spawnx, _spawny, _brushscale, _brushscale, 0, c_white, 1.0);
	container.cellAddEnd();
}
// rain
raintoggle ^= keyboard_check_pressed(ord("5"));
if (raintoggle) {
	container.cellAddBegin(FluxCell.Depth);
	container.cellAddSetRange(-10.0, 50.0);
	repeat 150 {
		draw_sprite_ext(dropmap, 0, irandom(container.cellSize), irandom(container.cellSize), 0.05 * power(2, quality), 0.05 * power(2, quality), 0, c_white, 1.0);
	}
	container.cellAddEnd();
}


// flux modification (kinda trash setup of cardinal directions)
//if mouse_check_button(mb_right) {
//	container.cellAddXYBegin(FluxCell.FluxRU, 0);
//	container.cellAddSetRange(-5.0, 2.0);
//	draw_sprite_ext(dropmap, 1, mouse_x, mouse_y, 0.1, 0.1, 0, c_white, 1.0);
//	container.cellAddEnd();
//	container.cellAddXYBegin(FluxCell.FluxRU, 1);
//	container.cellAddSetRange(-5.0, 2.0);
//	draw_sprite_ext(dropmap, 1, mouse_x, mouse_y, 0.1, 0.1, 0, c_white, 1.0);
//	container.cellAddEnd();
//	container.cellAddXYBegin(FluxCell.FluxLD, 0);
//	container.cellAddSetRange(2.0, -5.0);
//	draw_sprite_ext(dropmap, 1, mouse_x, mouse_y, 0.1, 0.1, 0, c_white, 1.0);
//	container.cellAddEnd();
//	container.cellAddXYBegin(FluxCell.FluxLD, 1);
//	container.cellAddSetRange(2.0, -5.0);
//	draw_sprite_ext(dropmap, 1, mouse_x, mouse_y, 0.1, 0.1, 0, c_white, 1.0);
//	container.cellAddEnd();
//}

// simulation step
container.stepFlux();
container.stepDepth();

// fragment lookup
var _cs = container.cellSize;
var _tx = floor(clamp(x * (_cs / worldxlen), 0, worldxlen)),
	_ty = floor(clamp(y * (_cs / worldylen), 0, worldylen));
var _idd = [container.lookupIdFromPosition(_tx, _ty)];
container.lookupWrite(
	[FluxCell.Height, FluxCell.Depth],	// get height and depth ...
	[_idd, _idd]						// ... of index matching player's xy
);
container.lookupCopy();	// copy to cpu readable memory, looked up with getZ() defined in create event

// ------------------------------- //
// Camera and movement
var _ms = 50 * (1 + keyboard_check(vk_shift) * 4);
if (keyboard_check(ord("W"))) {
	x += dcos(yaw) * _ms;
	y -= dsin(yaw) * _ms;
}
if (keyboard_check(ord("A"))) {
	x -= dsin(yaw) * _ms;
	y -= dcos(yaw) * _ms;
}
if (keyboard_check(ord("S"))) {
	x -= dcos(yaw) * _ms;
	y += dsin(yaw) * _ms;
}
if (keyboard_check(ord("D"))) {
	x += dsin(yaw) * _ms;
	y += dcos(yaw) * _ms;
}
z = getZ() - 2048;

if mouse_check_button(mb_right) {
	yaw -= clamp((window_mouse_get_x() - window_get_width() / 2) / 40, -2, 2);
	pitch -= clamp((window_mouse_get_y() - window_get_height() / 2) / 40, -2, 2);
	pitch = clamp(pitch, -90, 90);
}
// window_mouse_set(window_get_width() / 2, window_get_height() / 2); // cba writing js to make this work on web

xto = x + dcos(yaw);
yto = y - dsin(yaw);
zto = z - dsin(pitch);

camera_set_view_mat(camera, matrix_build_lookat(x, y, z, xto, yto, zto, 0, 0, 1));
camera_set_proj_mat(camera, matrix_build_projection_perspective_fov(60, window_get_width() / window_get_height(), 1, 32000));
camera_apply(camera);

// start the rendering process
draw_clear(c_black);
gpu_set_ztestenable(false);
gpu_set_zwriteenable(false);
gpu_set_cullmode(cull_clockwise);

// quick and lazy non-cubemap-sampled skybox, credit @XorDev
var _stex = sprite_get_texture(skytex,0),
	_suvs = sprite_get_uvs(skytex,0);

shader_set(shd_sky);
shader_set_uniform_f(shader_get_uniform(shd_sky,"uvs"), _suvs[0], _suvs[1], _suvs[2] - _suvs[0], _suvs[3] - _suvs[1] );
vertex_submit(buf_sky, pr_trianglelist, _stex);
shader_reset();

gpu_set_ztestenable(true);
gpu_set_zwriteenable(true);
gpu_set_cullmode(cull_counterclockwise);

// ---------------------------- //
// draw terrain
var _scx = 1,//(vwidth / worldxlen),
	_scy = 1;//(vheight / worldylen);
//var _posx = ( (x - vwidth / 2 * _scx) div _scx) * _scx,
//	_posy = ( (y - vheight / 2 * _scy) div _scy) * _scy;
var _posx = (x div 1024) * 1024,
	_posy = (y div 1024) * 1024;

var _shader = shd_terrain;
shader_set(_shader);
gpu_set_tex_repeat(1);
gpu_set_tex_mip_filter(tf_anisotropic);
texture_set_stage(shader_get_sampler_index(_shader, "u_uSampler"), surface_get_texture(container.fluxSurface));
gpu_set_tex_filter_ext(shader_get_sampler_index(_shader, "u_uSampler"), 1);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uSamplerUVs"), 0.0, 0.0, 0.5, 0.5);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWorldSize"), worldxlen, worldylen, worldzlen);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWRegion"), 1024, 1024, worldxlen-1024, worldylen-1024);

shader_set_uniform_f(shader_get_uniform(_shader, "u_uPosition"), _posx, _posy);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uScale"), _scx, _scy);
vertex_submit(vbuffer, pr_trianglelist, sprite_get_texture(terraintexhd, 0));
shader_reset();

// prep zbuffer
surface_set_target(zbuffer);
draw_clear_alpha(0x80745e, 1.0);
var _shader = shd_terrain_z;
gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
camera_apply(camera);
shader_set(_shader);
texture_set_stage(shader_get_sampler_index(_shader, "u_uSampler"), surface_get_texture(container.fluxSurface));
gpu_set_tex_filter_ext(shader_get_sampler_index(_shader, "u_uSampler"), 1);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uSamplerUVs"), 0.0, 0.0, 0.5, 0.5);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWorldSize"), worldxlen, worldylen, worldzlen);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWRegion"), 1024, 1024, worldxlen-1024, worldylen-1024);

shader_set_uniform_f(shader_get_uniform(_shader, "u_uPosition"), _posx, _posy);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uScale"), _scx, _scy);
vertex_submit(vbuffer, pr_trianglelist, -1);
shader_reset();
gpu_set_blendmode(bm_normal);
surface_reset_target();

// ---------------------------- //
// draw caustics
camera_apply(camera);
gpu_set_blendmode(bm_add);
gpu_set_zwriteenable(false);

var _shader = shd_caustics;
shader_set(_shader);
texture_set_stage(shader_get_sampler_index(_shader, "u_uSampler"), surface_get_texture(container.fluxSurface));
gpu_set_tex_filter_ext(shader_get_sampler_index(_shader, "u_uSampler"), 1);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uSamplerSize"), container.texSize, container.texSize);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uSamplerUVs"), 0.0, 0.0, 0.5, 0.5);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWaterUVs"), 0.5, 0.0, 1.0, 0.5);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWorldSize"), worldxlen, worldylen, worldzlen);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uSunray"), 0.44, 0.56, 0.45);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uPosition"), _posx, _posy);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uScale"), _scx, _scy);

shader_set_uniform_f(shader_get_uniform(_shader, "u_uDepthFalloff"), 1 / 1000);

shader_set_uniform_f(shader_get_uniform(_shader, "u_uFragmentTime"), current_time / 10000);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWRegion"), 1024, 1024, worldxlen-1024, worldylen-1024);

vertex_submit(vbuffer, pr_trianglelist, sprite_get_texture(caustictex, 0));
shader_reset();

// ---------------------------- //
// draw water level

// prep framebuffer
gpu_set_blendmode_ext(bm_one, bm_zero);
gpu_set_ztestenable(false);
surface_set_target(fbuffer);
draw_surface(application_surface, 0, 0);
surface_reset_target();

// prep render sampler
surface_set_target(rbuffer);
draw_surface(fbuffer, 0, 0);
draw_surface(zbuffer, 0, surface_get_height(fbuffer) );
draw_sprite_stretched(skytex, 0, 0, room_height * 2, room_width, room_height); // should ideally be only done once but it is what it is...
surface_reset_target();

gpu_set_blendmode(bm_normal);
gpu_set_ztestenable(true);

// render
camera_apply(camera);
gpu_set_zwriteenable(true);
gpu_set_cullmode(cull_noculling);

var _shader = shd_waterlevel;
shader_set(_shader);
texture_set_stage(shader_get_sampler_index(_shader, "u_uSampler"), surface_get_texture(container.fluxSurface));
gpu_set_tex_filter_ext(shader_get_sampler_index(_shader, "u_uSampler"), 1);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uSamplerSize"), container.texSize, container.texSize);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uSamplerUVs"), 0.0, 0.0, 0.5, 0.5);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWaterUVs"), 0.5, 0.0, 1.0, 0.5);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWorldSize"), worldxlen, worldylen, worldzlen);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uSunray"), 0.44, 0.56, 0.45);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uPosition"), _posx, _posy);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uScale"), _scx, _scy);

shader_set_uniform_f(shader_get_uniform(_shader, "u_uWaterColBegin"), 0.5, 0.9, 1.0, 0.0);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWaterColEnd"), 0.1, 0.5, 0.9, 0.0);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uReflectionRange"), 0.25, 0.85, 30000);

shader_set_uniform_f(shader_get_uniform(_shader, "u_uWaterColFalloff"), 1 / 2000);

shader_set_uniform_f(shader_get_uniform(_shader, "u_uDepthFalloff"), 1 / 1000);

shader_set_uniform_f(shader_get_uniform(_shader, "u_uVertexTime"), current_time / 100);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWRegion"), 1024, 1024, worldxlen-1024, worldylen-1024);

vertex_submit(vbuffer, wiretoggle ? pr_linelist : pr_trianglelist, surface_get_texture(rbuffer));
shader_reset();

// ---------------------------- //
// draw advected texture (foam)

// prep advection samplers
surface_set_target(abuffer);
gpu_set_blendmode(bm_add);
var _shader = shd_foamgen;
shader_set(_shader);
texture_set_stage(shader_get_sampler_index(_shader, "u_uSampler"), surface_get_texture(container.fluxSurface) );
shader_set_uniform_f(shader_get_uniform(_shader, "u_uFragTime"), current_time / 100);
draw_sprite_stretched(foamtex, 0, 0, 0, advectSize, advectSize);
shader_reset();
gpu_set_blendmode(bm_normal);
surface_reset_target();

surface_set_target(abuffer_pong);
gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
var _shader = shd_advect;
shader_set(_shader);
texture_set_stage(shader_get_sampler_index(_shader, "u_uSampler"), surface_get_texture(container.fluxSurface) );
shader_set_uniform_f(shader_get_uniform(_shader, "u_uFragTime"), current_time / 100);
draw_surface(abuffer, 0, 0);
gpu_set_blendmode(bm_normal);
surface_reset_target();
shader_reset();
var _temp = abuffer_pong;
abuffer_pong = abuffer;
abuffer = _temp;

// render foam
camera_apply(camera);
gpu_set_zwriteenable(false);

var _shader = shd_foam;
shader_set(_shader);
texture_set_stage(shader_get_sampler_index(_shader, "u_uSampler"), surface_get_texture(container.fluxSurface));
gpu_set_tex_filter_ext(shader_get_sampler_index(_shader, "u_uSampler"), 1);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uSamplerSize"), container.texSize, container.texSize);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uSamplerUVs"), 0.0, 0.0, 0.5, 0.5);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWaterUVs"), 0.5, 0.0, 1.0, 0.5);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWorldSize"), worldxlen, worldylen, worldzlen);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uPosition"), _posx, _posy);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uScale"), _scx, _scy);
shader_set_uniform_f(shader_get_uniform(_shader, "u_uWRegion"), 1024, 1024, worldxlen-1024, worldylen-1024);

if (!wiretoggle) vertex_submit(vbuffer, pr_trianglelist, surface_get_texture(abuffer));
shader_reset();

gpu_set_zwriteenable(true);
