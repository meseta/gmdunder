function DunderSocket() : DunderBaseStruct() constructor { REGISTER_SUBTYPE(DunderSocket);
	// A list wrapper
	
	static __init__ = function(_socket_type, _host, _port, _raw=true, _logger=undefined) {
		socket_type = _socket_type;
		host = _host;
		port = _port;
		raw = _raw;
		
		packet_callback = undefined;
		connect_callback = undefined;
		disconnect_callback = undefined;
		step_callback = undefined;
		
		socket = -1;
		__connected = false;
		__disconnected_time = 0;
		__should_be_connected = false
		__listener_instance = undefined;
		
		if (is_undefined(_logger)) {
			logger = dunder.bind_named_logger("Socket", {host:host, port:port})
		}
		else {
			logger = _logger;	
		}
	}
	
	static __cleanup__ = function() {
		disconnect();
		if (not is_undefined(_listener_instance)) {
			__listener_instance.__cleanup__();
			delete __listener_instance;
		}
	}
	static cleanup = __cleanup__;
	
	static __boolean__ = function() {
		return __connected;	
	}
	static boolean = __boolean__;
	
	// Socket functions
	static is_connected = function() {
		return __connected;	
	}
	static set_packet_callback = function(_func) {
		packet_callback = _func;
		return self;
	}
	static set_connect_callback = function(_func) {
		connect_callback = _func;
		return self;
	}
	static set_disconnect_callback = function(_func) {
		disconnect_callback = _func;
		return self;
	}
	static set_step_callback = function(_func) {
		step_callback = _func;
		return self;
	}
	
	static connect = function() {
		if (socket >= 0) {
			return;
		}
		socket = network_create_socket(socket_type);
		if (socket < 0) {
			logger.error("Could not create socket, not available");
		}
		
		if (is_undefined(__listener_instance)) {
			__listener_instance = dunder.create_instance(__obj_dunder_socket_listener, 0, 0, 0, undefined,
				[method(self, __step_handler), method(self, __async_networking_handler)]
			);
		}
		
		network_set_config(network_config_connect_timeout, 5000);
		network_set_config(network_config_use_non_blocking_socket, 1);
		if (raw) {
			network_connect_raw(socket, host, port);
		}
		else {
			network_connect(socket, host, port);
		}
		__should_be_connected = true;
		__disconnected_time = 0;
		logger.info("Connecting")
	}

	static disconnect = function() {
		if (socket < 0) {
			return;
		}
		logger.info("Disconnecting")
		network_destroy(socket);
		socket = -1;
		__should_be_connected = false;
		__connected = false;
	}
	
	static send_buffer = function(_buff, _size) {
		if (socket >= 0) {
			if (raw) {
				return network_send_raw(socket, _buff, _size);
			}
			else {
				return network_send_packet(socket, _buff, _size);
			}
		}
		return 0;
	}
	
	static send_string = function(_input) {
		var _string = dunder.as_string(_input);
		var _len = string_byte_length(_string);
		var _buff = buffer_create(_len, buffer_fixed, 1);
		buffer_write(_buff, buffer_text, _string);
		
		var _result = send_buffer(_buff, _len);
		buffer_delete(_buff);
		return _result;
	}
	
	static __async_networking_handler = function(_async_load) {
		if (_async_load[? "id"] != socket) {
			return
		}
		var _type = _async_load[? "type"];
		
		switch (_type) {
			case network_type_connect:
				show_debug_message(json_encode(_async_load))
				break;
			case network_type_non_blocking_connect:
				// There seems to be a bug where a non-blocking connect will fire an async event that says "succeeded"
				// 
				if (_async_load[? "succeeded"]) {
					__connected = true;				
					__disconnected_time = 0;
					logger.info("Connected")
					if (is_method(connect_callback)) {
						connect_callback();
					}
				}
				else {
					__connected = false;	
				}
				break

			case network_type_disconnect:
				__connected = false;
				logger.info("Disconnected")
				if (is_method(disconnect_callback)) {
					disconnect_callback();
				}
				connect();
				break;
				
			case network_type_data:
				var _buffer = _async_load[? "buffer"];
				var _size = _async_load[? "size"];
				if (is_method(packet_callback)) {
					packet_callback(_buffer, _size);
				}
				break;
		}
	}
	
	static __step_handler = function() {
		if (not __connected and __should_be_connected) {
			__disconnected_time += 1;
			if (__disconnected_time > game_get_speed(gamespeed_fps) * 5) {
				__disconnected_time = 0;
				logger.warning("Connection stale, reconnecting...")
				disconnect();
				connect();
			}
		}
		if (is_method(step_callback)) {
			step_callback();	
		}
	}
}