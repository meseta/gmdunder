function DunderReversed() : DunderBaseStruct() constructor {
	// An object that reverses another object
	__bases_add__(DunderReversed);
	
	static __init__ = function(_target) {
		if (__dunder__.is_struct_with_method(_target, "__getitem__") and
			__dunder__.is_struct_with_method(_target, "__len__")) {
			target = _target;
			target_len = target.__len__()
		}
		else {
			throw __dunder__.init(DunderExceptionTypeError, "Expected List type dunder");	
		}
	}
	static __repr__ = function() {
		return "<dunder '"+instanceof(self)+" target="+instanceof(target_len)+">";
	}
	
	static __iter__ = function() {
		return __dunder__.init(DunderIterator, method(self, __getitem__), target_len);
	}
	
	static __len__ = function() {
		return target_len;
	}
	
	static __getitem__ = function(_index) {
		return target.__getitem__(target_len - _index - 1);
	}
}