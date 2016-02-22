
vms.Classic = function() {
	var vm = this;

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

	this.dices = [];
	this.callMethod = function(operator, codes, context, args) {

		if (context === "get") {

			if (operator === "_operatorPlus") return codes[0](vm, "get") + codes[1](vm, "get");
			if (operator === "_operatorMinus") return codes[0](vm, "get") - codes[1](vm, "get");
			if (operator === "_operatorAsterisk") return codes[0](vm, "get") * codes[1](vm, "get");
			if (operator === "_operatorSlash") return codes[0](vm, "get") / codes[1](vm, "get");
			if (operator === "_leftPlus") return codes[0](vm, "get");
			if (operator === "_leftMinus") return -codes[0](vm, "get");
			if (operator === "_bracketsRound") return codes[0](vm, "get");
			if (operator === "d") return dice(codes[0](vm, "get"), codes[1](vm, "get"));

			throw "Unknown operator: " + operator;
		} else {
			throw "Unknown context: " + context;
		}
	};
	this.unpackBlessed = function(value) {
		return value;
	};
	this.allTrue = function(array) {
		for (var i = 0; i < array.length; i++) {
			if (!array[i]) return false;
		}
		return true;
	};
	this.createLiteral = function(type, value) {
		return value;
	};
};
