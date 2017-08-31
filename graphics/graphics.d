module graphics.graphics;

import proto;

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
}
