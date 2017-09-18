module graphics.sdl;

import graphics.graphics;
import graphics.scancode;
import maybe;
import derelict.sdl2.image, derelict.sdl2.sdl, derelict.sdl2.ttf;


private void sdlerror() {
	import std.string: fromStringz;
	throw new Exception(cast(string)("Error from SDL.  SDL says: " ~ fromStringz(SDL_GetError())));
}

final class Graphicsdl: Graphics {
	private SDL_Window *window;
	private SDL_Renderer *renderer;
	private TTF_Font*[uint] fonts;

	void init(GraphicsPrefs gprefs) {
		version (dynamic_sdl2) {
			DerelictSDL2.load();
			DerelictSDL2Image.load();
			DerelictSDL2TTF.load();
		}

		if (SDL_Init(SDL_INIT_VIDEO|SDL_INIT_EVENTS) < 0)
			sdlerror();
		if (!(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG))
			sdlerror();
		if (TTF_Init() == -1)
			sdlerror();

		SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");


		window = SDL_CreateWindow(null, gprefs.x, gprefs.y,
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
		foreach (font; fonts.values)
			TTF_CloseFont(font);

		TTF_Quit();
		IMG_Quit();
		SDL_Quit();
	}

	void placesprite(Sprite s, int x, int y, Maybe!Colour clrmod, Maybe!Colour bg) {
		if (s.gfx_type != Gfx_type.GRAPHICS_SDL)
			throw new Exception("Tried to draw a non-sdl sprite using sdl rendering!");


		SDL_Rect rect;

		rect.x = x;
		rect.y = y;

		SDL_QueryTexture(cast(SDL_Texture*)s.data, null, null, &rect.w, &rect.h);

		if (s.overridew > -1) rect.w = s.overridew;
		if (s.overrideh > -1) rect.h = s.overrideh;
		rect.w *= s.scalefactor;
		rect.h *= s.scalefactor;

		if (bg.isset) {
			SDL_SetRenderDrawColor(renderer, bg.r, bg.g, bg.b, bg.a);
			SDL_RenderFillRect(renderer, &rect);
			SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
		}

		if (clrmod.isset) {
			SDL_SetTextureColorMod(cast(SDL_Texture*)s.data, clrmod.r, clrmod.g, clrmod.b);
		}

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
	void loadfont(string path, uint index, uint height=18) {
		import std.string: toStringz;

		fonts[index] = TTF_OpenFont(toStringz(path), height);
		if (!fonts[index]) sdlerror();
	}
	void rendertext(ref Sprite sprite, string text, uint font, Maybe!Colour clr = nothing!Colour) {
		import std.string: toStringz;
		sprite.gfx_type = Gfx_type.GRAPHICS_SDL;

		SDL_Color white = SDL_Color(255, 255, 255, 0);
		SDL_Surface *surf = TTF_RenderUTF8_Blended(fonts[font], toStringz(text), white);
		sprite.data = SDL_CreateTextureFromSurface(renderer, surf);

		if (clr.isset)
			SDL_SetTextureColorMod(cast(SDL_Texture*)sprite.data, clr.r, clr.g, clr.b);

		SDL_FreeSurface(surf);
	}

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

	Maybe!Event pollevent() {
		SDL_Event ev;

		if (SDL_PollEvent(&ev) && ev.type == SDL_KEYDOWN || ev.type == SDL_KEYUP) {
			Event ret;
			ret.key = sdltokey(ev.key.keysym.sym);
			ret.type = (ev.type == SDL_KEYDOWN) ? Evtype.Keydown : Evtype.Keyup;

			return just(ret);
		} else {
			return nothing!Event;
		}
	}

	Event waitevent() {
		return Event();
	}

	void settitle(string title) {
		import std.string: toStringz;

		SDL_SetWindowTitle(window, toStringz(title));
	}

	private Key sdltokey(SDL_Keycode sdl) {
		return [SDLK_UNKNOWN: Key.unknown,
			SDLK_RETURN: Key.enter,
			SDLK_ESCAPE: Key.escape,
			SDLK_BACKSPACE: Key.backspace,
			SDLK_TAB: Key.tab,
			SDLK_SPACE: Key.space,
			SDLK_EXCLAIM: Key.exclaim,
			SDLK_QUOTEDBL: Key.quotedbl,
			SDLK_HASH: Key.hash,
			SDLK_PERCENT: Key.percent,
			SDLK_DOLLAR: Key.dollar,
			SDLK_AMPERSAND: Key.ampersand,
			SDLK_QUOTE: Key.quote,
			SDLK_LEFTPAREN: Key.leftparen,
			SDLK_RIGHTPAREN: Key.rightparen,
			SDLK_ASTERISK: Key.asterisk,
			SDLK_PLUS: Key.plus,
			SDLK_COMMA: Key.comma,
			SDLK_MINUS: Key.minus,
			SDLK_PERIOD: Key.period,
			SDLK_SLASH: Key.slash,
			SDLK_0: Key.num_0,
			SDLK_1: Key.num_1,
			SDLK_2: Key.num_2,
			SDLK_3: Key.num_3,
			SDLK_4: Key.num_4,
			SDLK_5: Key.num_5,
			SDLK_6: Key.num_6,
			SDLK_7: Key.num_7,
			SDLK_8: Key.num_8,
			SDLK_9: Key.num_9,
			SDLK_COLON: Key.colon,
			SDLK_SEMICOLON: Key.semicolon,
			SDLK_LESS: Key.less,
			SDLK_EQUALS: Key.equals,
			SDLK_GREATER: Key.greater,
			SDLK_QUESTION: Key.question,
			SDLK_AT: Key.at,
			SDLK_LEFTBRACKET: Key.leftbracket,
			SDLK_BACKSLASH: Key.backslash,
			SDLK_RIGHTBRACKET: Key.rightbracket,
			SDLK_CARET: Key.caret,
			SDLK_UNDERSCORE: Key.underscore,
			SDLK_BACKQUOTE: Key.backquote,
			SDLK_a: Key.a,
			SDLK_b: Key.b,
			SDLK_c: Key.c,
			SDLK_d: Key.d,
			SDLK_e: Key.e,
			SDLK_f: Key.f,
			SDLK_g: Key.g,
			SDLK_h: Key.h,
			SDLK_i: Key.i,
			SDLK_j: Key.j,
			SDLK_k: Key.k,
			SDLK_l: Key.l,
			SDLK_m: Key.m,
			SDLK_n: Key.n,
			SDLK_o: Key.o,
			SDLK_p: Key.p,
			SDLK_q: Key.q,
			SDLK_r: Key.r,
			SDLK_s: Key.s,
			SDLK_t: Key.t,
			SDLK_u: Key.u,
			SDLK_v: Key.v,
			SDLK_w: Key.w,
			SDLK_x: Key.x,
			SDLK_y: Key.y,
			SDLK_z: Key.z,

			SDLK_CAPSLOCK: Key.capslock,

			SDLK_F1: Key.f1,
			SDLK_F2: Key.f2,
			SDLK_F3: Key.f3,
			SDLK_F4: Key.f4,
			SDLK_F5: Key.f5,
			SDLK_F6: Key.f6,
			SDLK_F7: Key.f7,
			SDLK_F8: Key.f8,
			SDLK_F9: Key.f9,
			SDLK_F10: Key.f10,
			SDLK_F11: Key.f11,
			SDLK_F12: Key.f12,

			SDLK_PRINTSCREEN: Key.printscreen,
			SDLK_SCROLLLOCK: Key.scrolllock,
			SDLK_PAUSE: Key.pause,
			SDLK_INSERT: Key.insert,
			SDLK_HOME: Key.home,
			SDLK_PAGEUP: Key.pageup,
			SDLK_DELETE: Key.key_delete,
			SDLK_END: Key.end,
			SDLK_PAGEDOWN: Key.pagedown,
			SDLK_RIGHT: Key.right,
			SDLK_LEFT: Key.left,
			SDLK_DOWN: Key.down,
			SDLK_UP: Key.up,

			SDLK_NUMLOCKCLEAR: Key.numlockclear,
			SDLK_KP_DIVIDE: Key.kp_divide,
			SDLK_KP_MULTIPLY: Key.kp_multiply,
			SDLK_KP_MINUS: Key.kp_minus,
			SDLK_KP_PLUS: Key.kp_plus,
			SDLK_KP_ENTER: Key.kp_enter,
			SDLK_KP_1: Key.kp_1,
			SDLK_KP_2: Key.kp_2,
			SDLK_KP_3: Key.kp_3,
			SDLK_KP_4: Key.kp_4,
			SDLK_KP_5: Key.kp_5,
			SDLK_KP_6: Key.kp_6,
			SDLK_KP_7: Key.kp_7,
			SDLK_KP_8: Key.kp_8,
			SDLK_KP_9: Key.kp_9,
			SDLK_KP_0: Key.kp_0,
			SDLK_KP_PERIOD: Key.kp_period,

			SDLK_APPLICATION: Key.application,
			SDLK_POWER: Key.power,
			SDLK_KP_EQUALS: Key.kp_equals,
			SDLK_F13: Key.f13,
			SDLK_F14: Key.f14,
			SDLK_F15: Key.f15,
			SDLK_F16: Key.f16,
			SDLK_F17: Key.f17,
			SDLK_F18: Key.f18,
			SDLK_F19: Key.f19,
			SDLK_F20: Key.f20,
			SDLK_F21: Key.f21,
			SDLK_F22: Key.f22,
			SDLK_F23: Key.f23,
			SDLK_F24: Key.f24,
			SDLK_EXECUTE: Key.execute,
			SDLK_HELP: Key.help,
			SDLK_MENU: Key.menu,
			SDLK_SELECT: Key.select,
			SDLK_STOP: Key.stop,
			SDLK_AGAIN: Key.again,
			SDLK_UNDO: Key.undo,
			SDLK_CUT: Key.cut,
			SDLK_COPY: Key.copy,
			SDLK_PASTE: Key.paste,
			SDLK_FIND: Key.find,
			SDLK_MUTE: Key.mute,
			SDLK_VOLUMEUP: Key.volumeup,
			SDLK_VOLUMEDOWN: Key.volumedown,
			SDLK_KP_COMMA: Key.kp_comma,
			SDLK_KP_EQUALSAS400: Key.kp_equalsas400,

			SDLK_ALTERASE: Key.alterase,
			SDLK_SYSREQ: Key.sysreq,
			SDLK_CANCEL: Key.cancel,
			SDLK_CLEAR: Key.clear,
			SDLK_PRIOR: Key.prior,
			SDLK_RETURN2: Key.return2,
			SDLK_SEPARATOR: Key.separator,
			SDLK_OUT: Key.key_out,
			SDLK_OPER: Key.oper,
			SDLK_CLEARAGAIN: Key.clearagain,
			SDLK_CRSEL: Key.crsel,
			SDLK_EXSEL: Key.exsel,

			SDLK_KP_00: Key.kp_00,
			SDLK_KP_000: Key.kp_000,
			SDLK_THOUSANDSSEPARATOR: Key.thousandsseparator,
			SDLK_DECIMALSEPARATOR: Key.decimalseparator,
			SDLK_CURRENCYUNIT: Key.currencyunit,
			SDLK_CURRENCYSUBUNIT: Key.currencysubunit,
			SDLK_KP_LEFTPAREN: Key.kp_leftparen,
			SDLK_KP_RIGHTPAREN: Key.kp_rightparen,
			SDLK_KP_LEFTBRACE: Key.kp_leftbrace,
			SDLK_KP_RIGHTBRACE: Key.kp_rightbrace,
			SDLK_KP_TAB: Key.kp_tab,
			SDLK_KP_BACKSPACE: Key.kp_backspace,
			SDLK_KP_A: Key.kp_a,
			SDLK_KP_B: Key.kp_b,
			SDLK_KP_C: Key.kp_c,
			SDLK_KP_D: Key.kp_d,
			SDLK_KP_E: Key.kp_e,
			SDLK_KP_F: Key.kp_f,
			SDLK_KP_XOR: Key.kp_xor,
			SDLK_KP_POWER: Key.kp_power,
			SDLK_KP_PERCENT: Key.kp_percent,
			SDLK_KP_LESS: Key.kp_less,
			SDLK_KP_GREATER: Key.kp_greater,
			SDLK_KP_AMPERSAND: Key.kp_ampersand,
			SDLK_KP_DBLAMPERSAND: Key.kp_dblampersand,
			SDLK_KP_VERTICALBAR: Key.kp_verticalbar,
			SDLK_KP_DBLVERTICALBAR: Key.kp_dblverticalbar,
			SDLK_KP_COLON: Key.kp_colon,
			SDLK_KP_HASH: Key.kp_hash,
			SDLK_KP_SPACE: Key.kp_space,
			SDLK_KP_AT: Key.kp_at,
			SDLK_KP_EXCLAM: Key.kp_exclam,
			SDLK_KP_MEMSTORE: Key.kp_memstore,
			SDLK_KP_MEMRECALL: Key.kp_memrecall,
			SDLK_KP_MEMCLEAR: Key.kp_memclear,
			SDLK_KP_MEMADD: Key.kp_memadd,
			SDLK_KP_MEMSUBTRACT: Key.kp_memsubtract,
			SDLK_KP_MEMMULTIPLY: Key.kp_memmultiply,
			SDLK_KP_MEMDIVIDE: Key.kp_memdivide,
			SDLK_KP_PLUSMINUS: Key.kp_plusminus,
			SDLK_KP_CLEAR: Key.kp_clear,
			SDLK_KP_CLEARENTRY: Key.kp_clearentry,
			SDLK_KP_BINARY: Key.kp_binary,
			SDLK_KP_OCTAL: Key.kp_octal,
			SDLK_KP_DECIMAL: Key.kp_decimal,
			SDLK_KP_HEXADECIMAL: Key.kp_hexadecimal,

			SDLK_LCTRL: Key.lctrl,
			SDLK_LSHIFT: Key.lshift,
			SDLK_LALT: Key.lalt,
			SDLK_LGUI: Key.lgui,
			SDLK_RCTRL: Key.rctrl,
			SDLK_RSHIFT: Key.rshift,
			SDLK_RALT: Key.ralt,
			SDLK_RGUI: Key.rgui,

			SDLK_MODE: Key.mode,

			SDLK_AUDIONEXT: Key.audionext,
			SDLK_AUDIOPREV: Key.audioprev,
			SDLK_AUDIOSTOP: Key.audiostop,
			SDLK_AUDIOPLAY: Key.audioplay,
			SDLK_AUDIOMUTE: Key.audiomute,
			SDLK_MEDIASELECT: Key.mediaselect,
			SDLK_WWW: Key.www,
			SDLK_MAIL: Key.mail,
			SDLK_CALCULATOR: Key.calculator,
			SDLK_COMPUTER: Key.computer,
			SDLK_AC_SEARCH: Key.ac_search,
			SDLK_AC_HOME: Key.ac_home,
			SDLK_AC_BACK: Key.ac_back,
			SDLK_AC_FORWARD: Key.ac_forward,
			SDLK_AC_STOP: Key.ac_stop,
			SDLK_AC_REFRESH: Key.ac_refresh,
			SDLK_AC_BOOKMARKS: Key.ac_bookmarks,

			SDLK_BRIGHTNESSDOWN: Key.brightnessdown,
			SDLK_BRIGHTNESSUP: Key.brightnessup,
			SDLK_DISPLAYSWITCH: Key.displayswitch,
			SDLK_KBDILLUMTOGGLE: Key.kbdillumtoggle,
			SDLK_KBDILLUMDOWN: Key.kbdillumdown,
			SDLK_KBDILLUMUP: Key.kbdillumup,
			SDLK_EJECT: Key.eject,
			SDLK_SLEEP: Key.sleep][sdl];
	}

	Rect getrect(Sprite sprite) {
		if (sprite.gfx_type != Gfx_type.GRAPHICS_SDL)
			throw new Exception("Tried to draw a non-sdl sprite using sdl rendering!");

		Rect ret;

		SDL_QueryTexture(cast(SDL_Texture*)sprite.data, null, null, &ret.w, &ret.h);

		if (sprite.overridew > -1)
			ret.w = sprite.overridew;

		if (sprite.overrideh > -1)
			ret.h = sprite.overrideh;

		ret.w *= sprite.scalefactor;
		ret.h *= sprite.scalefactor;

		return ret;
	}
}
