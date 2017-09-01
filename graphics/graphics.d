module graphics.graphics;

package enum Gfx_type {
	GRAPHICS_NONE,
	GRAPHICS_SDL,
	GRAPHICS_SFML
}

struct Sprite {
	int overridew = -1, overrideh = -1;

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

interface Graphics {
	void init(GraphicsPrefs prefs);
	void end();
	void placesprite(Sprite s, int x, int y);
	void clear();
	void blit();
	void loadsprite(ref Sprite sprite, string fpath);

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
}
