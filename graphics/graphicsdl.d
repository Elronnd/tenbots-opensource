module graphics.sdl;

import graphics.graphics;
import proto;
import derelict.sdl2.image, derelict.sdl2.sdl;


private void sdlerror() {
	import std.string: fromStringz;
	throw new Exception(cast(string)("Error from SDL.  SDL says: " ~ fromStringz(SDL_GetError())));
}

final class Graphicsdl: Graphics {
	private SDL_Window *window;
	private SDL_Renderer *renderer;

	void init(GraphicsPrefs gprefs) {
		version (dynamic_sdl2) {
			DerelictSDL2.load();
			DerelictSDL2Image.load();
		}

		if (SDL_Init(SDL_INIT_VIDEO|SDL_INIT_EVENTS) < 0) {
			sdlerror();
		}

		window = SDL_CreateWindow("Ten bots", gprefs.x, gprefs.y,
				gprefs.winwidth ? gprefs.winwidth : 1366,
				gprefs.winheight ? gprefs.winheight : 768,
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
			auto getwidth = () {
				SDL_DisplayMode dm;
				if (SDL_GetCurrentDisplayMode(0, &dm) != 0)
					sdlerror();

				return dm.w;
			};
			auto getheight = () {
				SDL_DisplayMode dm;
				if (SDL_GetCurrentDisplayMode(0, &dm) != 0)
					sdlerror();

				return dm.h;
			};
			SDL_RenderSetLogicalSize(renderer, gprefs.logicalwidth ? gprefs.logicalwidth : getwidth(), gprefs.logicalheight ? gprefs.logicalheight : getheight());
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
}