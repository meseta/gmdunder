function DunderRange() : DunderBaseStruct() constructor { REGISTER_SUBTYPE(DunderRange);
	// A range of values
	static __init__ = function(_start, _stop, _step=1) {
		if (not is_numeric(_start)) {
			throw dunder.init(DunderExceptionValueError, "Start must be numeric");	
		}
		if (not is_numeric(_stop)) {
			throw dunder.init(DunderExceptionValueError, "Stop must be numeric");	
		}
		if (not is_numeric(_step)) {
			throw dunder.init(DunderExceptionValueError, "Step must be numeric");	
		}
		
		if (_step == 0) {
			throw dunder.init(DunderExceptionValueError, "Step can't be zero");	
		}
		if (_start != _stop and sign(_stop-_start) != sign(_step)) {
			throw dunder.init(DunderExceptionValueError, "Start and stop value doesn't match step");	
		}
		
		start = _start;
		stop = _stop;
		step = _step;
	}
	
	// Representation methods
	static __repr__ = function() {
		return "<dunder '"+instanceof(self)+" start="+string(start)+" stop="+string(stop)+" step="+string(step)+">";
	}
	static __array__ = function() {
		var _len = __len__();
		var _array = array_create(_len);
		for (var _i=0; _i<_len; _i++) {
			_array[_i] = __getitem__(_i);
		}
		return _array;
	}
	
	// Structure methods
	static __len__ = function() {
		return ceil((stop - start)/step);
	}
	static __getitem__ = function(_index) {
		return start + _index*step;
	}
	
	// Iteration methods
	static __iter__ = function() {
		return dunder.init(DunderIterator, method(self, __getitem__), __len__());
	}
}