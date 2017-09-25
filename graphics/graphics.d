module graphics.graphics;

import graphics.scancode;
import maybe;

package enum Gfx_type {
	GRAPHICS_NONE,
	GRAPHICS_SDL,
	GRAPHICS_SFML
}

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
	double scalefactor = 1;

	package {
		void *data;
		Gfx_type gfx_type;
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


interface Graphics {
	void init(GraphicsPrefs prefs);
	void end();
	void placesprite(Sprite s, int x, int y, Maybe!Colour clrmod = nothing!Colour, Maybe!Colour bg = nothing!Colour);
	void clear();
	void blit();
	void loadsprite(ref Sprite sprite, string fpath);

	void loadfont(string path, uint index, uint height=36);
	void rendertext(ref Sprite sprite, string text, uint font, Maybe!Colour clr = nothing!Colour);

	uint screenw();
	uint screenh();

	uint winw();
	uint winh();

	float dpih();
	float dpiw();

	bool istruefullscreen();
	void settruefullscreen(bool state);
	final void toggletruefullscreen() {
		settruefullscreen(!istruefullscreen());
	}

	bool isdesktopfullscreen();
	void setdesktopfullscreen(bool state);
	final void toggledesktopfullscreen() {
		setdesktopfullscreen(!isdesktopfullscreen());
	}

	bool isvsync();

	bool hasborders();
	void setborders(bool on);
	final void toggleborders() {
		setborders(!hasborders());
	}

	void getlogicalsize(ref uint w, ref uint h);
	void setlogicalsize(uint w, uint h);

	void setwinw(uint w);
	void setwinh(uint h);
	void setwinsize(uint w, uint h);

	Maybe!Event pollevent();
	Event waitevent();

	void settitle(string title);

	Rect getrect(Sprite sprite);
}
