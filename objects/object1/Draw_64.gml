if keyboard_check(ord("Q")) {
	var _shader = GMFluxShd_visualizeDepth;
	shader_set(_shader);
	draw_surface_part(container.fluxSurface, container.cellSize, 0, container.cellSize, container.cellSize, 0, 0);
	shader_reset();
}

if keyboard_check(ord("E")) {
	var _shader = GMFluxShd_visualizeFlux;
	shader_set(_shader);
	draw_surface_part(container.fluxSurface, 0, container.cellSize, container.cellSize, container.cellSize, 0, 0);
	shader_reset();
}

if keyboard_check(ord("F")) {
	draw_surface_ext(abuffer_pong, 0, 0, 0.25, 0.25, 0, c_white, 1.0);
	shader_reset();
}

if keyboard_check(ord("X")) {
	draw_surface_ext(zbuffer, 0, 0, 0.25, 0.25, 0, c_white, 1.0);
}

// instructions
instructoggle ^= keyboard_check_pressed(ord("I"));
if (instructoggle) {
	var _instr = "WASD - Move\nShift - Sprint\n1 - Add water\n2 - Subtract water\n3 - Add terrain\n4 - Subtract terrain\n";
	_instr += "5 - Toggle rain (" + string(raintoggle) + ")\n";
	_instr += "Enter - Toggle wireframe (" + string(wiretoggle) + ")\n";
	_instr += "Mouse Wheel - Brush size (" + (brushsize < 5 ? string(brushsize) : "Global") + ")\n";
	_instr += "Mouse RB - Rotate view\n";
	var _oc = draw_get_color();
	draw_set_color(c_black);
	draw_text(8, 8, _instr);
	draw_set_color(_oc);
}
