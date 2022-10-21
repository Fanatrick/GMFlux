function GMFlux_lodNode(_parent = undefined) constructor {
	//	1 - 2 - 3
	//	| \ | / |
	//	4 - X - 5	0 - 1
	//	| / | \ |	|   |
	//	6 - 7 - 8	2 - 3
	edgeFlags = 165;	// 8 flags (1010 0101)
	parent = _parent;
	quadrant = 0;
	depth = 0;
	
	subbed = false;
	branches = undefined;
	
	static open = function(_quadrant) {
	/// @func			open(quadrant)
	/// @description	opens a quadrant
		if (!subbed) __branchout();
		var _node = new GMFlux_lodNode(self);
		_node.quadrant = _quadrant;
		_node.depth = depth + 1;
		// apply masks
		var _qdat = __quadrantdat[_quadrant];
		edgeFlags ^= _qdat.edgeToggle;
		edgeFlags &= ~_qdat.edgeOff;
		// set quadrant
		branches[_quadrant] = _node;
	}
	static openAll = function() {
	/// @func			openAll()
	/// @description	open all quadrants
		if (subbed) exit;
		__branchout();
		open(0);
		open(1);
		open(2);
		open(3);
	}
	static edge = function(_edgeid, _flags) {
	/// @func			edge(edge, [flags])
	/// @description	toggles an edge of this node (or a different one supplied with _flags)
		var _fl = _flags ?? edgeFlags;
	    return (1 & (_fl >> (_edgeid)));
	}
	static edgeGetCount = function() {
	/// @func			edgeGetCount()
	/// @description	output a number open edges
		return __flagcountlut[edgeFlags];
	}
	static propagate = function(_method) {
	/// @func			propagate(method)
	/// @description	propagates a method throughout the mesh (breadth-first, newly created nodes inside the method are also affected)
		var _m = method(self, _method);
		_m();
		if (subbed) {
			for(var i = 0; i < 4; i ++) {
				var _q = branches[i];
				if is_undefined(_q) continue;
				_q.propagate(_method);
			}
		}
	}
	
	#region Internal
	static __searchresults = [];
	static __branchout = function() {
		branches = array_create(4, undefined);
		subbed = true;
	}
	static __flagcountlutcreate = function() {
		var _lut = array_create(256, 0)
	    for (var i = 0; i < 256; i ++) {
	        _lut[i] = (i & 1) + _lut[i div 2];
	    }
		return _lut;
	}
	static __flagcountlut = __flagcountlutcreate();
	static __edgetripos = [
		[-1, -1],	[0, -1],	[1, -1],
		[-1, 0],				[1, 0],
		[-1, 1],	[0, 1],		[1, 1]
	];
	static __flagedgeclockwise = [0, 1, 2, 4, 7, 6, 5, 3];
	static __flagtrianglelutcreate = function() {
		var _lut = array_create(256);
	    for (var i = 0; i < 256; i ++) {
			var _trilist = [];	// list of triangle edges (2 per-entry, 3rd is always center)
			// find first vertice
			for(var j = 0; j < 8; j ++) {
				if (!edge(__flagedgeclockwise[j], i)) continue;
				// find next
				for(var k = 1; k <= 2; k ++) {
					if (!edge(__flagedgeclockwise[(j + k) % 8], i)) continue;
					array_push(_trilist, [__edgetripos[__flagedgeclockwise[j]], __edgetripos[__flagedgeclockwise[(j + k) % 8]] ]);
					j += k - 1;
					break;
				}
			}
			array_set(_lut, i, _trilist);
	    }
		return _lut;
	}
	static __flagtrianglelut = __flagtrianglelutcreate();
	static __quadrantdat = [
		// NW
		{
			edgeToggle	: 10,		// 2, 4	(0000 1010)
			edgeOff		: 1			// 1	(0000 0001)
		},
		// NE
		{
			edgeToggle	: 18,		// 2, 5	(0001 0010)
			edgeOff		: 4			// 3	(0000 0100)
		},
		// SW
		{
			edgeToggle	: 72,		// 4, 7	(0100 1000)
			edgeOff		: 32		// 6	(0010 0000)
		},
		// SE
		{
			edgeToggle	: 80,		// 5, 7	(0101 0000)
			edgeOff		: 128		// 8	(1000 0000)
		}
	];
	#endregion
	
}