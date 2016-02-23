
vms.Standard = function() {
	var vm = this;

	function getVariable(name)
	{
		return variables[name] || UNDEFINED;
	}
	function createObject(type, value)
	{
		return {
			type: type,
			value: value,
		};
	}
	function dice(count, faces)
	{
		var t = 0, i, value, values = [];
		for (i = 0; i < count; i++) {
			value = Math.floor(Math.random() * faces) + 1;
			t += value;
			values.push(value);
		}
		vm.dices.push(values);
		return t;
	}
	function visitScalar(array, blessed)
	{
		if (instanceOf(blessed, typeVector)) {
			for (var i = 0; i < blessed.value.length; i++) {
				visitScalar(array, blessed.value[i]);
			}
		} else {
			array.push(blessed);
		}
	}
	function packVector(array)
	{
		var array2 = [];
		array.forEach(function(item) { visitScalar(array2, item); });
		if (array2.length == 1) return array2[0];
		return createObject(typeVector, array2);
	}
	function unpackVector(blessed)
	{
		if (instanceOf(blessed, typeVector)) return blessed.value;
		return [blessed];
	}
	function instanceOf(blessed, type)
	{
		return blessed.type === type;
	}

	var typeType = createObject(null, "Type"); typeType.type = typeType;
	var typeUndefined = createObject(typeType, "Undefined");
	var typeNumber = createObject(typeType, "Number");
	var typeString = createObject(typeType, "String");
	var typeKeyword = createObject(typeType, "Keyword");
	var typeBoolean = createObject(typeType, "Boolean");
	var typeFunction = createObject(typeType, "Function");
	var typePointer = createObject(typeType, "Pointer");
	var typeArray = createObject(typeType, "Array");
	var typeVector = createObject(typeType, "Vector");
	var typeEntry = createObject(typeType, "Entry");
	
	var UNDEFINED = createObject(typeUndefined, undefined);

	var variables = {
		pi: createObject(typeNumber, Math.PI),
		sin: createObject(typeFunction, function(value) { return createObject(typeNumber, Math.sin(value.value)); }),
	};

	this.dices = [];
	this.callMethod = function(operator, codes, context, args) {
		if (operator === "_leftAsterisk") return codes[0](vm, "get").value(vm, context, args);
		if (context === "get") {

			if (operator === "_operatorPlus") return createObject(typeNumber, codes[0](vm, "get").value + codes[1](vm, "get").value);
			if (operator === "_operatorMinus") return createObject(typeNumber, codes[0](vm, "get").value - codes[1](vm, "get").value);
			if (operator === "_operatorAsterisk") return createObject(typeNumber, codes[0](vm, "get").value * codes[1](vm, "get").value);
			if (operator === "_operatorSlash") return createObject(typeNumber, codes[0](vm, "get").value / codes[1](vm, "get").value);
			if (operator === "_leftPlus") return createObject(typeNumber, codes[0](vm, "get").value);
			if (operator === "_leftMinus") return createObject(typeNumber, -codes[0](vm, "get").value);
			if (operator === "_bracketsRound") return codes[0](vm, "get");
			if (operator === "_operatorGreater") return createObject(typeBoolean, codes[0](vm, "get").value > codes[1](vm, "get").value);
			if (operator === "_operatorGreaterEqual") return createObject(typeBoolean, codes[0](vm, "get").value >= codes[1](vm, "get").value);
			if (operator === "_operatorLess") return createObject(typeBoolean, codes[0](vm, "get").value < codes[1](vm, "get").value);
			if (operator === "_operatorLessEqual") return createObject(typeBoolean, codes[0](vm, "get").value <= codes[1](vm, "get").value);
			if (operator === "_operatorEqual2") return createObject(typeBoolean, codes[0](vm, "get").value == codes[1](vm, "get").value);
			if (operator === "_operatorExclamationEqual") return createObject(typeBoolean, codes[0](vm, "get").value != codes[1](vm, "get").value);
			if (operator === "_operatorPipe2") return createObject(typeBoolean, codes[0](vm, "get").value || codes[1](vm, "get").value);
			if (operator === "_operatorTilde") {
				var left = codes[0](vm, "get").value;
				var right = codes[1](vm, "get").value;
				var array = [];
				for (var i = left; i <= right; i++) {
					array.push(createObject(typeNumber, i));
				}
				return packVector(array);
			}
			if (operator === "_operatorAmpersand2") return createObject(typeBoolean, codes[0](vm, "get").value && codes[1](vm, "get").value);
			if (operator === "_enumerateComma") return packVector(codes.map(function(code) { return code(vm, "get"); }));
			if (operator === "_bracketsSquare") {
				return createObject(typeArray, unpackVector(codes[0](vm, "get")));
			}
			if (operator === "_rightbracketsSquare") {
				var value = codes[0](vm, "get");
				if (instanceOf(value, typeKeyword)) value = getVariable(value.value);
				if (instanceOf(value, typeArray)) return value.value[codes[1](vm, "get").value] || UNDEFINED;
				throw "Type Error: " + operator + "/" + value.type.value;
			}
			if (operator === "_leftAtsign") {
				var value = codes[0](vm, "get");
				if (instanceOf(value, typeArray)) return createObject(typeVector, value.value);
				throw "Type Error: " + operator + "/" + value.type.value;
			}
			if (operator === "_operatorMinus2Greater"
				|| operator === "_operatorEqual2Greater") 	{
				var minus = operator == "_operatorMinus2Greater" || operator == "_operatorMinusGreater";
				if (minus) {
					return packVector(unpackVector(codes[0](vm, "get")).map(function(scalar) {
						variables["_"] = scalar;
						return codes[1](vm, "get");
					}));
				} else {
					variables["_"] = codes[0](vm, "get");
					return codes[1](vm, "get");
				}
			}
			if (operator === "_operatorColon") return createObject(typeEntry, {
				key: codes[0](vm, "get").value,
				value: codes[1](vm, "get").value,
			});
			if (operator === "d") return createObject(typeNumber, dice(codes[0](vm, "get").value, codes[1](vm, "get").value));
			if (operator === "_leftDollar") return getVariable(codes[0](vm, "get").value);
			if (operator === "_rightbracketsRound") {
				var value = codes[0](vm, "get");
				if (instanceOf(value, typeKeyword)) value = getVariable(value.value);
				if (instanceOf(value, typeFunction)) return value.value(codes[1](vm, "get"));
				throw "Type Error: " + operator + "/" + value.type.value;
			}
			if (operator === "_statement") {
				var command = codes[0](vm, "get");
				if (command.value === "typeof") {
					var value = codes[1](vm, "get");
					return value.type;
				}
				throw "Unknown command: " + command.value;
			}
			if (operator === "_leftAmpersand") return createObject(typePointer, codes[0]);

			throw "Unknown operator: " + operator;
		} else {
			throw "Unknown context: " + context;
		}
	};
	this.toString = function(value) {
		var vm = this;
		if (instanceOf(value, typeVector)) {
			return value.value.map(function(scalar) { return vm.toString(scalar); }).join(", ");
		}
		if (instanceOf(value, typeArray)) {
			return "[" + value.value.map(function(scalar) { return vm.toString(scalar); }).join(", ") + "]";
		}
		if (instanceOf(value, typeEntry)) {
			return value.value.key + ": " + value.value.value;
		}
		if (instanceOf(value, typeFunction)) {
			return "<Function>";
		}
		if (instanceOf(value, typePointer)) {
			return "<Pointer>";
		}
		if (instanceOf(value, typeType)) {
			return "<Type: " + value.value + ">";
		}
		return "" + value.value;
	};
	this.toNative = function(value) {
		var vm = this;
		if (instanceOf(value, typeVector)) {
			return value.value.map(function(scalar) { return vm.toNative(scalar); });
		}
		if (instanceOf(value, typeArray)) {
			return value.value.map(function(scalar) { return vm.toNative(scalar); });
		}
		return value.value;
	};
	this.allTrue = function(array) {
		for (var i = 0; i < array.length; i++) {
			if (!array[i].value) return createObject(typeBoolean, false);
		}
		return createObject(typeBoolean, true);
	};
	this.createLiteral = function(type, value) {
		if (type === "Integer") return createObject(typeNumber, value);
		if (type === "Float") return createObject(typeNumber, value);
		if (type === "String") return createObject(typeString, value);
		if (type === "Identifier") {
			if (value === "true") return createObject(typeBoolean, true);
			if (value === "false") return createObject(typeBoolean, false);
			if (value === "undefined") return UNDEFINED;
			return createObject(typeKeyword, value);
		}
		if (type === "Underbar") return createObject(typeKeyword, value);
		throw "Unknown type: " + type;
	};
};

