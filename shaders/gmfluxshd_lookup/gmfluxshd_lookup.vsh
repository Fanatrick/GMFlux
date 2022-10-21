attribute vec3 in_Position;                  // (index, none)

varying vec4 v_vColor;

uniform vec2 u_uSizePass;		// (w, h)
uniform vec3 u_uSize;			// (cellSize, slotSize, texSize)

uniform float u_uListOffset;
uniform float u_uListIds[32];
uniform float u_uListCells[32];

uniform sampler2D u_uSampler;

float disgusting1(int _index) {
	float res = 0.0;
	if (_index == 0)		{res = u_uListIds[0];}
	else if (_index == 1)	{res = u_uListIds[1];}
	else if (_index == 2)	{res = u_uListIds[2];}
	else if (_index == 3)	{res = u_uListIds[3];}
	else if (_index == 4)	{res = u_uListIds[4];}
	else if (_index == 5)	{res = u_uListIds[5];}
	else if (_index == 6)	{res = u_uListIds[6];}
	else if (_index == 7)	{res = u_uListIds[7];}
	else if (_index == 8)	{res = u_uListIds[8];}
	else if (_index == 9)	{res = u_uListIds[9];}
	else if (_index == 10)	{res = u_uListIds[10];}
	else if (_index == 11)	{res = u_uListIds[11];}
	else if (_index == 12)	{res = u_uListIds[12];}
	else if (_index == 13)	{res = u_uListIds[13];}
	else if (_index == 14)	{res = u_uListIds[14];}
	else if (_index == 15)	{res = u_uListIds[15];}
	else if (_index == 16)	{res = u_uListIds[16];}
	else if (_index == 17)	{res = u_uListIds[17];}
	else if (_index == 18)	{res = u_uListIds[18];}
	else if (_index == 19)	{res = u_uListIds[19];}
	else if (_index == 20)	{res = u_uListIds[20];}
	else if (_index == 21)	{res = u_uListIds[21];}
	else if (_index == 22)	{res = u_uListIds[22];}
	else if (_index == 23)	{res = u_uListIds[23];}
	else if (_index == 24)	{res = u_uListIds[24];}
	else if (_index == 25)	{res = u_uListIds[25];}
	else if (_index == 26)	{res = u_uListIds[26];}
	else if (_index == 27)	{res = u_uListIds[27];}
	else if (_index == 28)	{res = u_uListIds[28];}
	else if (_index == 29)	{res = u_uListIds[29];}
	else if (_index == 30)	{res = u_uListIds[30];}
	else if (_index == 31)	{res = u_uListIds[31];}
	return res;
}
float disgusting2(int _index) {
	float res = 0.0;
	if (_index == 0)		{res = u_uListCells[0];}
	else if (_index == 1)	{res = u_uListCells[1];}
	else if (_index == 2)	{res = u_uListCells[2];}
	else if (_index == 3)	{res = u_uListCells[3];}
	else if (_index == 4)	{res = u_uListCells[4];}
	else if (_index == 5)	{res = u_uListCells[5];}
	else if (_index == 6)	{res = u_uListCells[6];}
	else if (_index == 7)	{res = u_uListCells[7];}
	else if (_index == 8)	{res = u_uListCells[8];}
	else if (_index == 9)	{res = u_uListCells[9];}
	else if (_index == 10)	{res = u_uListCells[10];}
	else if (_index == 11)	{res = u_uListCells[11];}
	else if (_index == 12)	{res = u_uListCells[12];}
	else if (_index == 13)	{res = u_uListCells[13];}
	else if (_index == 14)	{res = u_uListCells[14];}
	else if (_index == 15)	{res = u_uListCells[15];}
	else if (_index == 16)	{res = u_uListCells[16];}
	else if (_index == 17)	{res = u_uListCells[17];}
	else if (_index == 18)	{res = u_uListCells[18];}
	else if (_index == 19)	{res = u_uListCells[19];}
	else if (_index == 20)	{res = u_uListCells[20];}
	else if (_index == 21)	{res = u_uListCells[21];}
	else if (_index == 22)	{res = u_uListCells[22];}
	else if (_index == 23)	{res = u_uListCells[23];}
	else if (_index == 24)	{res = u_uListCells[24];}
	else if (_index == 25)	{res = u_uListCells[25];}
	else if (_index == 26)	{res = u_uListCells[26];}
	else if (_index == 27)	{res = u_uListCells[27];}
	else if (_index == 28)	{res = u_uListCells[28];}
	else if (_index == 29)	{res = u_uListCells[29];}
	else if (_index == 30)	{res = u_uListCells[30];}
	else if (_index == 31)	{res = u_uListCells[31];}
	return res;
}

vec2 fragPosition(float _index) {
	return vec2(mod(_index, u_uSizePass.x), floor(_index / u_uSizePass.x));
}

vec2 nodePosition(float _index) {
	return vec2(mod(_index, u_uSize.y), floor(_index / u_uSize.y))+0.5;
}
vec2 slotPosition(float _slot) {
	return vec2(mod(_slot, u_uSize.x) * u_uSize.y, floor(_slot / u_uSize.x) * u_uSize.y);
}

vec4 lookup(in float _index, in float _slot) {
	vec2 _pos = (nodePosition(_index) + slotPosition(_slot)) / u_uSize.z;
	return texture2D(u_uSampler, _pos);
}

void main() {
    vec2 pos = 1.0 + fragPosition(in_Position.x + u_uListOffset);
	
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(pos, 0.0, 1.0);
	gl_PointSize = 1.0;
	
	int ind = int(floor(in_Position.x + 0.5));
    v_vColor = lookup(disgusting1(ind), disgusting2(ind) );
}

