module graphics.graphics;

import graphics.scancode;
import maybe;
public import graphics.sdl: Graphics;

struct Point {
	int x, y;
}


struct Rect {
	int x, y, w, h;

	Point topleft() {
		return Point(x, y);
	}

	Point bottomleft() {
		return Point(x, y + h);
	}

	Point topright() {
		return Point(x + w, y);
	}

	Point bottomright() {
		return Point(x + w, y + h);
	}



	pure bool collides(Rect other) {
		immutable int x1 = x,
			y1 = y,
			x2 = x + w,
			y2 = y + h,
			ox1 = other.x,
			oy1 = other.y,
			ox2 = other.x + other.w,
			oy2 = other.y + other.h;


		immutable bool xcollides = ((x1 <= ox1) && (ox1 <= x2)) || ((x1 <= ox2) && (ox2 <= x2)),
				ycollides = ((y1 <= oy1) && (oy1 <= y2)) || ((y1 <= oy2) && (oy2 <= y2));

		return xcollides && ycollides;

		// Found this on SO.  It passes the unittests, but it fails when actually playing.  *shrug*
		//return (abs(x - other.x) * 2 < (w + other.w)) &&
		//	(abs(y - other.y) * 2 < (h + other.h));

	}


	unittest {
		// same shape
		foreach (_; 0 .. 1000) {
			import std.random: uniform, rndGen;

			// c and d are unsigned because how can you have negative length?
			int a = uniform!short(rndGen()), b = uniform!short(rndGen()), c = uniform!ushort(rndGen()), d = uniform!ushort(rndGen());

			assert (Rect(a, b, c, d).collides(Rect(a, b, c, d)));
		}

		assert (Rect(5, 9, 7, 4).collides(Rect(5, 9, 7, 4)));



		// failure
		assert (!Rect(3, 2, 7, 2).collides(Rect(0, 0, 2, 1)));

		// Contact along one line
		assert (Rect(3, 2, 7, 2).collides(Rect(0, 2, 3, 0)));

		// Contact along one point
//		assert (Rect(3, 2, 7, 2).collides(Rect(0, 0, 3, 2)));
	}
}

struct Sprite {
	int overridew = -1, overrideh = -1;
	float scalefactor = 1;
	real x, y;

	Texture texture;

	void load(string fpath) {
		texture.load(fpath);
	}

	Rect getrect() {
		return Graphics.getrect(this);
	}
}

struct Texture {
	package void *data;
	void load(string fpath) {
		Graphics.loadtexture(this, fpath);
	}
}

struct GraphicsPrefs {
	uint winwidth, winheight;
	uint logicalwidth, logicalheight;
	int x, y;

	bool use_vsync = true, use_hardware_acceleration = true;

	enum Fullscreenstate { True, Desktop, None };
	Fullscreenstate fullscreen = Fullscreenstate.None;
	bool borderless = true;
}

struct Colour {
	ubyte r, g, b, a = 255;
}

enum Evtype {
	Keydown,
	Keyup,
}


struct Event {
	union {
		Key key;
	}

	Evtype type;
}
