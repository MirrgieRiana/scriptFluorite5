
vms.Standard = function() {
	this.dices = [];
	this.callMethod = function(operator, codes, context, args) {
		var vm = this;

		var variables = {
			pi: Math.PI,
		};
		var dice = function(count, faces) {
			var t = 0, i, value, values = [];
			for (i = 0; i < count; i++) {
				value = Math.floor(Math.random() * faces) + 1;
				t += value;
				values.push(value);
			}
			dices.push(values);
			return t;
		};

		if (context === "get") {

			if (operator === "_operatorPlus") return codes[0](vm, "get") + codes[1](vm, "get");
			if (operator === "_operatorMinus") return codes[0](vm, "get") - codes[1](vm, "get");
			if (operator === "_operatorAsterisk") return codes[0](vm, "get") * codes[1](vm, "get");
			if (operator === "_operatorSlash") return codes[0](vm, "get") / codes[1](vm, "get");
			if (operator === "_leftPlus") return codes[0](vm, "get");
			if (operator === "_leftMinus") return -codes[0](vm, "get");
			if (operator === "_bracketsRound") return codes[0](vm, "get");
			if (operator === "_operatorGreater") return codes[0](vm, "get") > codes[1](vm, "get");
			if (operator === "_operatorGreaterEqual") return codes[0](vm, "get") >= codes[1](vm, "get");
			if (operator === "_operatorLess") return codes[0](vm, "get") < codes[1](vm, "get");
			if (operator === "_operatorLessEqual") return codes[0](vm, "get") <= codes[1](vm, "get");
			if (operator === "_operatorEqual2") return codes[0](vm, "get") == codes[1](vm, "get");
			if (operator === "_operatorExclamationEqual") return codes[0](vm, "get") != codes[1](vm, "get");
			if (operator === "_operatorPipe2") return codes[0](vm, "get") || codes[1](vm, "get");
			if (operator === "_operatorAmpersand2") return codes[0](vm, "get") && codes[1](vm, "get");
			if (operator === "_enumerateComma") return codes.map(function(code) { return code(vm, "get"); });
			if (operator === "_operatorMinus2Greater") return codes[0](vm, "get").map(function(code) { return codes[1](vm, "get"); });
			if (operator === "d") return dice(codes[0](vm, "get"), codes[1](vm, "get"));
			if (operator === "_leftDollar") return variables[codes[0](vm, "get")];

			throw "Unknown operator: " + operator;
		} else {
			throw "Unknown context: " + context;
		}
	};
	this.unpackBlessed = function(value) {
		return value;
	};
	this.toBoolean = function(value) {
		return value.value;
	};
	this.createBoolean = function(value) {
		return this.createObject("Boolean", value);
	};
	this.createLiteral = function(type, value) {
		return value;
	};
};

