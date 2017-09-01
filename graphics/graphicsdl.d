module graphics.sdl;

import graphics.graphics;
import derelict.sdl2.image, derelict.sdl2.sdl;


private void sdlerror() {
	import std.string: fromStringz;
	throw new Exception(cast(string)("Error from SDL.  SDL says: " ~ fromStringz(SDL_GetError())));
}

final class Graphicsdl: Graphics {
	private SDL_Window *window;
	private SDL_Renderer *renderer;

	uint screenw() {
		SDL_DisplayMode dm;
		if (SDL_GetCurrentDisplayMode(0, &dm) != 0)
			sdlerror();

		return dm.w;
	}
	uint screenh() {
		SDL_DisplayMode dm;
		if (SDL_GetCurrentDisplayMode(0, &dm) != 0)
			sdlerror();

		return dm.h;
	}
	uint winw() {
		int ret;
		SDL_GetWindowSize(window, &ret, null);

		return ret;
	}
	uint winh() {
		int ret;
		SDL_GetWindowSize(window, null, &ret);

		return ret;
	}
	void setwinw(uint w) {
		SDL_SetWindowSize(window, w, winh());
	}
	void setwinh(uint h) {
		SDL_SetWindowSize(window, winw(), h);
	}
	void setwinsize(uint w, uint h) {
		SDL_SetWindowSize(window, w, h);
	}

	float dpih() {
		float ret;
		SDL_GetDisplayDPI(0, null, &ret, null);

		return ret;
	}
	float dpiw() {
		float ret;
		SDL_GetDisplayDPI(0, null, null, &ret);

		return ret;
	}

	void init(GraphicsPrefs gprefs) {
		version (dynamic_sdl2) {
			DerelictSDL2.load();
			DerelictSDL2Image.load();
		}

		if (SDL_Init(SDL_INIT_VIDEO|SDL_INIT_EVENTS) < 0) {
			sdlerror();
		}

		window = SDL_CreateWindow("Ten bots", gprefs.x, gprefs.y,
				gprefs.winwidth ? gprefs.winwidth : screenw(),
				gprefs.winheight ? gprefs.winheight : screenh(),
				() {
					SDL_WindowFlags ret = gprefs.borderless ? SDL_WINDOW_BORDERLESS : cast(SDL_WindowFlags)0;

					final switch (gprefs.fullscreen) with(GraphicsPrefs.Fullscreenstate) {
						case True: ret |= SDL_WINDOW_FULLSCREEN; break;
						case Desktop: ret |= SDL_WINDOW_FULLSCREEN_DESKTOP; break;
						case None: break;
					}
					return ret;
				}());
		if (!window) sdlerror();

		renderer = SDL_CreateRenderer(window, -1, (gprefs.use_hardware_acceleration ? SDL_RENDERER_ACCELERATED : SDL_RENDERER_SOFTWARE) |
		// sdl complains if we try to use vsync and hardware acceleration at the same time
		((gprefs.use_vsync && gprefs.use_hardware_acceleration) ? SDL_RENDERER_PRESENTVSYNC : cast(SDL_RendererFlags)0));

		if (gprefs.logicalwidth || gprefs.logicalheight) {
			SDL_RenderSetLogicalSize(renderer, gprefs.logicalwidth ? gprefs.logicalwidth : screenw(), gprefs.logicalheight ? gprefs.logicalheight : screenh());
		}
	}
	void end() {
		SDL_Quit();
	}

	void placesprite(Sprite s, int x, int y) {
		if (s.gfx_type != Gfx_type.GRAPHICS_SDL)
			throw new Exception("Tried to draw a non-sdl sprite using sdl rendering!");


		SDL_Rect rect;

		rect.x = x;
		rect.y = y;

		SDL_QueryTexture(cast(SDL_Texture*)s.data, null, null, &rect.w, &rect.h);

		if (s.overridew > -1) rect.w = s.overridew;
		if (s.overrideh > -1) rect.h = s.overrideh;

		SDL_RenderCopy(renderer, cast(SDL_Texture*)s.data, null, &rect);
	}

	void clear() {
		SDL_RenderClear(renderer);
	}

	void blit() {
		SDL_RenderPresent(renderer);
	}

	void loadsprite(ref Sprite s, string fpath) {
		import std.string: toStringz;

		s.gfx_type = Gfx_type.GRAPHICS_SDL;

		SDL_Surface *surf = IMG_Load(toStringz(fpath));
		if (!surf) sdlerror();

		s.data = SDL_CreateTextureFromSurface(renderer, surf);

		SDL_FreeSurface(surf);
	}

	bool istruefullscreen() {
		return cast(bool)(SDL_GetWindowFlags(window) & SDL_WINDOW_FULLSCREEN);
	}
	void settruefullscreen(bool state) {
		if (SDL_SetWindowFullscreen(window, state ? SDL_WINDOW_FULLSCREEN : 0) < 0)
			sdlerror();
	}

	bool isdesktopfullscreen() {
		// I've said it before, and I'll say it again.  In D int doesn't automatically coerce to int and that's fucking retarted!
		return cast(bool)(SDL_GetWindowFlags(window) & SDL_WINDOW_FULLSCREEN_DESKTOP);
	}
	void setdesktopfullscreen(bool state) {
		if (SDL_SetWindowFullscreen(window, state ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0) < 0)
			sdlerror();
	}

	bool isvsync() {
		SDL_RendererInfo ri;
		SDL_GetRendererInfo(renderer, &ri);

		return cast(bool)(ri.flags & SDL_RENDERER_PRESENTVSYNC);
	}

	bool hasborders() {
		return !(SDL_GetWindowFlags(window) & SDL_WINDOW_BORDERLESS);
	}
	void setborders(bool on) {
		SDL_SetWindowBordered(window, on ? SDL_TRUE : SDL_FALSE);
	}

	void getlogicalsize(ref uint w, ref uint h) {
		SDL_RenderGetLogicalSize(renderer, cast(int*)&w, cast(int*)&h);
	}
	void setlogicalsize(uint w, uint h) {
		if (SDL_RenderSetLogicalSize(renderer, w, h) < 0)
			sdlerror();
	}
}
