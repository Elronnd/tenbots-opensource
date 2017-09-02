module maybe;

class Maybe(T) {
	abstract T opCall(T defaultVal);
}

Maybe!T just(T)(T val) {
	class Just(T): Maybe!T {
		this(T val) {
			_val = val;
		}
		override T opCall(T defaultVal) {
			return _val;
		}

		private T _val;
	}

	return new Just!T(val);
}

Maybe!T nothing(T)() {
	class Nothing(T): Maybe!T {
		override T opCall(T defaultVal) {
			return defaultVal;
		}
	}

	return new Nothing!T;
}


unittest {
	auto opt1 = just!int(1);
	assert (opt1(0) == 1);

	auto opt2 = nothing!int();
	assert (opt2(1) == 1);

	auto opt3 = just!string("test");
	assert (opt3("def") == "test");

	auto opt4 = nothing!string();
	assert (opt4("def") == "def");

	auto opt5 = nothing!(Maybe!int)();
	assert (opt5(just!int(7))(3) == 7);

	auto opt6 = just!(Maybe!char)(just!char('d'));
	assert (opt6(nothing!char())('c') == 'd');
}
