
vms.Standard = function() {
	this.dices = [];
	this.callMethod = function(operator, codes, context, args) {
		var vm = this;

		var variables = {
			pi: this.createObject("Number", Math.PI),
		};
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
		function packVector(array)
		{
			if (array.length == 1) return array[0];
			return vm.createObject("Vector", array);
		}
		function unpackVector(blessed)
		{
			if (blessed.type === "Vector") return blessed.value;
			return [blessed.value];
		}
		
		if (context === "get") {

			if (operator === "_operatorPlus") return this.createObject("Number", codes[0](vm, "get").value + codes[1](vm, "get").value);
			if (operator === "_operatorMinus") return this.createObject("Number", codes[0](vm, "get").value - codes[1](vm, "get").value);
			if (operator === "_operatorAsterisk") return this.createObject("Number", codes[0](vm, "get").value * codes[1](vm, "get").value);
			if (operator === "_operatorSlash") return this.createObject("Number", codes[0](vm, "get").value / codes[1](vm, "get").value);
			if (operator === "_leftPlus") return this.createObject("Number", codes[0](vm, "get").value);
			if (operator === "_leftMinus") return this.createObject("Number", -codes[0](vm, "get").value);
			if (operator === "_bracketsRound") return codes[0](vm, "get");
			if (operator === "_operatorGreater") return this.createObject("Boolean", codes[0](vm, "get").value > codes[1](vm, "get").value);
			if (operator === "_operatorGreaterEqual") return this.createObject("Boolean", codes[0](vm, "get").value >= codes[1](vm, "get").value);
			if (operator === "_operatorLess") return this.createObject("Boolean", codes[0](vm, "get").value < codes[1](vm, "get").value);
			if (operator === "_operatorLessEqual") return this.createObject("Boolean", codes[0](vm, "get").value <= codes[1](vm, "get").value);
			if (operator === "_operatorEqual2") return this.createObject("Boolean", codes[0](vm, "get").value == codes[1](vm, "get").value);
			if (operator === "_operatorExclamationEqual") return this.createObject("Boolean", codes[0](vm, "get").value != codes[1](vm, "get").value);
			if (operator === "_operatorPipe2") return this.createObject("Boolean", codes[0](vm, "get").value || codes[1](vm, "get").value);
			if (operator === "_operatorAmpersand2") return this.createObject("Boolean", codes[0](vm, "get").value && codes[1](vm, "get").value);
			if (operator === "_enumerateComma") return packVector(codes.map(function(code) { return code(vm, "get"); }));
			if (operator === "_operatorMinus2Greater") return packVector(unpackVector(codes[0](vm, "get")).map(function(code) { return codes[1](vm, "get"); }));
			if (operator === "d") return this.createObject("Number", dice(codes[0](vm, "get").value, codes[1](vm, "get").value));
			if (operator === "_leftDollar") return variables[codes[0](vm, "get").value];

			throw "Unknown operator: " + operator;
		} else {
			throw "Unknown context: " + context;
		}
	};
	this.createObject = function(type, value) {
		return {
			type: type,
			value: value,
		};
	};
	this.unpackBlessed = function(value) {
		if (value.type === "Vector") {
			return value.value.map(this.unpackBlessed);
		}
		return value.value;
	};
	this.toBoolean = function(value) {
		return value.value;
	};
	this.createBoolean = function(value) {
		return this.createObject("Boolean", value);
	};
	this.createLiteral = function(type, value) {
		if (type === "Integer") return this.createObject("Number", value);
		if (type === "Float") return this.createObject("Number", value);
		if (type === "Identifier") return this.createObject("Keyword", value);
		throw "Unknown type: " + type;
	};
};

