
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
		if (instanceOf(blessed, "Vector")) {
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
		return createObject("Vector", array2);
	}
	function unpackVector(blessed)
	{
		if (instanceOf(blessed, "Vector")) return blessed.value;
		return [blessed];
	}
	function instanceOf(blessed, type)
	{
		return blessed.type === type;
	}

	var variables = {
		pi: createObject("Number", Math.PI),
		sin: createObject("Function", function(value) { return createObject("Number", Math.sin(value.value)); }),
	};
	var UNDEFINED = createObject("Undefined", undefined);

	this.dices = [];
	this.callMethod = function(operator, codes, context, args) {
		if (context === "get") {

			if (operator === "_operatorPlus") return createObject("Number", codes[0](vm, "get").value + codes[1](vm, "get").value);
			if (operator === "_operatorMinus") return createObject("Number", codes[0](vm, "get").value - codes[1](vm, "get").value);
			if (operator === "_operatorAsterisk") return createObject("Number", codes[0](vm, "get").value * codes[1](vm, "get").value);
			if (operator === "_operatorSlash") return createObject("Number", codes[0](vm, "get").value / codes[1](vm, "get").value);
			if (operator === "_leftPlus") return createObject("Number", codes[0](vm, "get").value);
			if (operator === "_leftMinus") return createObject("Number", -codes[0](vm, "get").value);
			if (operator === "_bracketsRound") return codes[0](vm, "get");
			if (operator === "_operatorGreater") return createObject("Boolean", codes[0](vm, "get").value > codes[1](vm, "get").value);
			if (operator === "_operatorGreaterEqual") return createObject("Boolean", codes[0](vm, "get").value >= codes[1](vm, "get").value);
			if (operator === "_operatorLess") return createObject("Boolean", codes[0](vm, "get").value < codes[1](vm, "get").value);
			if (operator === "_operatorLessEqual") return createObject("Boolean", codes[0](vm, "get").value <= codes[1](vm, "get").value);
			if (operator === "_operatorEqual2") return createObject("Boolean", codes[0](vm, "get").value == codes[1](vm, "get").value);
			if (operator === "_operatorExclamationEqual") return createObject("Boolean", codes[0](vm, "get").value != codes[1](vm, "get").value);
			if (operator === "_operatorPipe2") return createObject("Boolean", codes[0](vm, "get").value || codes[1](vm, "get").value);
			if (operator === "_operatorTilde") {
				var left = codes[0](vm, "get").value;
				var right = codes[1](vm, "get").value;
				var array = [];
				for (var i = left; i <= right; i++) {
					array.push(createObject("Number", i));
				}
				return packVector(array);
			}
			if (operator === "_operatorAmpersand2") return createObject("Boolean", codes[0](vm, "get").value && codes[1](vm, "get").value);
			if (operator === "_enumerateComma") return packVector(codes.map(function(code) { return code(vm, "get"); }));
			if (operator === "_bracketsSquare") {
				return createObject("Array", unpackVector(codes[0](vm, "get")));
			}
			if (operator === "_rightbracketsSquare") {
				var value = codes[0](vm, "get");
				if (instanceOf(value, "Keyword")) value = getVariable(value.value);
				if (instanceOf(value, "Array")) return value.value[codes[1](vm, "get").value] || UNDEFINED;
				throw "Type Error: " + operator + "/" + value.type;
			}
			if (operator === "_leftAtsign") {
				var value = codes[0](vm, "get");
				if (instanceOf(value, "Array")) return createObject("Vector", value.value);
				throw "Type Error: " + operator + "/" + value.type;
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
			if (operator === "_operatorColon") return createObject("Entry", {
				key: codes[0](vm, "get").value,
				value: codes[1](vm, "get").value,
			});
			if (operator === "d") return createObject("Number", dice(codes[0](vm, "get").value, codes[1](vm, "get").value));
			if (operator === "_leftDollar") return getVariable(codes[0](vm, "get").value);
			if (operator === "_rightbracketsRound") {
				var value = codes[0](vm, "get");
				if (instanceOf(value, "Keyword")) value = getVariable(value.value);
				if (instanceOf(value, "Function")) return value.value(codes[1](vm, "get"));
				throw "Type Error: " + operator + "/" + value.type;
			}
			if (operator === "_statement") {
				var command = codes[0](vm, "get");
				if (command.value === "typeof") {
					var value = codes[1](vm, "get");
					return createObject("String", value.type);
				}
				throw "Unknown command: " + command;
			}

			throw "Unknown operator: " + operator;
		} else {
			throw "Unknown context: " + context;
		}
	};
	this.toString = function(value) {
		var vm = this;
		if (instanceOf(value, "Vector")) {
			return value.value.map(function(scalar) { return vm.toString(scalar); }).join(", ");
		}
		if (instanceOf(value, "Array")) {
			return "[" + value.value.map(function(scalar) { return vm.toString(scalar); }).join(", ") + "]";
		}
		return "" + value.value;
	};
	this.toNative = function(value) {
		var vm = this;
		if (instanceOf(value, "Vector")) {
			return value.value.map(function(scalar) { return vm.toNative(scalar); });
		}
		if (instanceOf(value, "Array")) {
			return value.value.map(function(scalar) { return vm.toNative(scalar); });
		}
		return value.value;
	};
	this.allTrue = function(array) {
		for (var i = 0; i < array.length; i++) {
			if (!array[i].value) return createObject("Boolean", false);
		}
		return createObject("Boolean", true);
	};
	this.createLiteral = function(type, value) {
		if (type === "Integer") return createObject("Number", value);
		if (type === "Float") return createObject("Number", value);
		if (type === "String") return createObject("String", value);
		if (type === "Identifier") {
			if (value === "true") return createObject("Boolean", true);
			if (value === "false") return createObject("Boolean", false);
			if (value === "undefined") return UNDEFINED;
			return createObject("Keyword", value);
		}
		if (type === "Underbar") return createObject("Keyword", value);
		throw "Unknown type: " + type;
	};
};

