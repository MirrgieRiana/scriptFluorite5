/*
 * Fluorite 5.8.1
 * ==============
 */

{

  function createCodeFromLiteral(type, value)
  {
    return function(vm, context, args) {
      return vm.createLiteral(type, value, context, args);
    };
  }

  function createCodeFromMethod(operator, codes)
  {
    return function(vm, context, args) {
      return vm.callOperator(operator, codes, context, args);
    };
  }

  function operatorLeft(head, tail)
  {
    var result = head, i;
    for (i = 0; i < tail.length; i++) {
      var operator = tail[i][1];
      if ((typeof operator) === "string") {
        result = createCodeFromMethod("operator" + operator, [result, tail[i][3]]);
      } else {
        result = createCodeFromMethod("operator" + operator[0], [result, operator[1], tail[i][3]]);
      }
    }
    return result;
  }

  function operatorRight(head, tail)
  {
    var result = tail, i;
    for (i = head.length - 1; i >= 0; i--) {
      var operator = head[i][2];
      if ((typeof operator) === "string") {
        result = createCodeFromMethod("operator" + operator, [head[i][0], result]);
      } else {
        result = createCodeFromMethod("operator" + operator[0], [head[i][0], operator[1], result]);
      }
    }
    return result;
  }

  function left(head, tail)
  {
    var result = tail, i;
    for (i = head.length - 1; i >= 0; i--) {
      var operator = head[i][0];
      if ((typeof operator) === "string") {
        result = createCodeFromMethod("left" + operator, [result]);
      } else {
        result = createCodeFromMethod("left" + operator[0], [operator[1], result]);
      }
    }
    return result;
  }

  function right(head, tail)
  {
    var result = head, i;
    for (i = 0; i < tail.length; i++) {
      var args = [result];
      Array.prototype.push.apply(args, tail[i][1][1]);
      result = createCodeFromMethod(tail[i][1][0], args);
    }
    return result;
  }

  function enumerate(head, tail, operator)
  {
    if (tail.length == 0) return head;
    var result = [head], i;
    for (i = 0; i < tail.length; i++) {
      result.push(tail[i][3]);
    }
    return createCodeFromMethod("enumerate" + operator, result);
  }

  function getVM(name)
  {
    if (name === "classic") {
      return function() {
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
        this.callOperator = function(operator, codes, context, args) {

          if (context === "get") {

            if (operator === "operatorPlus") return codes[0](vm, "get", []) + codes[1](vm, "get", []);
            if (operator === "operatorMinus") return codes[0](vm, "get", []) - codes[1](vm, "get", []);
            if (operator === "operatorAsterisk") return codes[0](vm, "get", []) * codes[1](vm, "get", []);
            if (operator === "operatorSlash") return codes[0](vm, "get", []) / codes[1](vm, "get", []);
            if (operator === "leftPlus") return codes[0](vm, "get", []);
            if (operator === "leftMinus") return -codes[0](vm, "get", []);
            if (operator === "bracketsRound") return codes[0](vm, "get", []);
            if (operator === "operatorComposite") return dice(codes[0](vm, "get", []), codes[2](vm, "get", []));

            throw "Unknown operator: " + operator;
          } else {
            throw "Unknown context: " + context;
          }
        };
        this.toString = function(value) {
          return "" + value;
        };
        this.toNative = function(value) {
          return value;
        };
        this.toBoolean = function(value) {
          return value;
        };
        this.createLiteral = function(type, value, context, args) {
          return value;
        };
      };
    } else if (name === "standard") {
      return (function() {

        function getProperty(hash, name)
        {
          var variable = Object.getOwnPropertyDescriptor(hash, name);
          if (variable != undefined) variable = variable.value;
          return variable;
        }

        var Scope = (function() {

          function Scope(parent, isFrame, UNDEFINED)
          {
            this.variables = {};
            this.parent = parent;
            this.isFrame = isFrame;
            this.UNDEFINED = UNDEFINED;

            this.id = Scope.id;
            Scope.id++;
          }
          Scope.id = 0;
          function getVariable(scope, name) 
          {
            var variable = getProperty(scope.variables, name);
            if (variable != undefined) {
              return variable;
            } else {
              if (scope.parent != undefined) {
                return getVariable(scope.parent, name);
              } else {
                return undefined;
              }
            }
          }
          Scope.prototype.define = function(name) {
            if (getVariable(this, name) != undefined) {
              throw "Duplicate variable definition: " + name;
            } else {
              this.variables[name] = {
                value: this.UNDEFINED,
              };
            }
          };
          Scope.prototype.get = function(name) {
            var variable = getVariable(this, name);
            if (variable != undefined) {
              return variable.value;
            } else {
              throw "Unknown variable: " + name;
            }
          };
          Scope.prototype.getOrUndefined = function(name) {
            var variable = getVariable(this, name);
            if (variable != undefined) {
              return variable.value;
            } else {
              return this.UNDEFINED;
            }
          };
          Scope.prototype.set = function(name, value) {
            var variable = getVariable(this, name);
            if (variable != undefined) {
              variable.value = value;
            } else {
              throw "Unknown variable: " + name;
            }
          };
          Scope.prototype.setOrDefine = function(name, value) {
            var variable = getVariable(this, name);
            if (variable != undefined) {
              variable.value = value;
            } else {
              this.variables[name] = {
                value: value,
              };
            }
          };
          Scope.prototype.defineOrSet = function(name, value) {
            var variable = getProperty(this.variables, name);
            if (variable != undefined) {
              variable.value = value;
            } else {
              this.variables[name] = {
                value: value,
              };
            }
          };
          Scope.prototype.getParentFrame = function(name, value) {
            if (this.parent.isFrame) {
              return this.parent;
            } else {
              return this.parent.getParentFrame();
            }
          };

          return Scope;
        })();

        function VMStandard()
        {
          var vm = this;

          function getMethodsOfTypeTree(keyword, blessedType)
          {
            var f;
            var functions = [];

            while (blessedType !== null) {

              f = getProperty(blessedType.value.members, keyword) || vm.UNDEFINED;
              if (!vm.instanceOf(f, vm.types.typeUndefined)) {
                functions.push(f);
              }

              blessedType = blessedType.value.supertype;
            }

            return functions;
          }

          vm.initBootstrap();

          vm.initLibrary();

          this.dices = [];
          this.loopCapacity = 10000;
          this.loopCount = 0;
          this.consumeLoopCapacity = function() {
            vm.loopCount++;
            if (vm.loopCount >= vm.loopCapacity) {
              throw "Internal Fluorite Error: Too many calculation(>= " + vm.loopCapacity + " steps)";
            }
          };

          this.callOperator = function(operator, codes, context, args) {
            vm.consumeLoopCapacity();

            function tryCallFromScope(name)
            {
              var blessedFunction = vm.scope.getOrUndefined(name);
              if (vm.instanceOf(blessedFunction, vm.types.typeUndefined)) return false;
              if (vm.instanceOf(blessedFunction, vm.types.typeFunction)) {
                var array = [vm.createObject(vm.types.typeString, context)];
                Array.prototype.push.apply(array, codes.map(function(code) { return vm.createPointer(code, vm.scope); }));
                var blessedPointer = vm.callFunction(blessedFunction, array);
                if (!vm.instanceOf(blessedPointer, vm.types.typePointer)) throw "Illegal type of operation result: " + blessedPointer.type.value.name;
                return vm.callPointer(blessedPointer, context, args);
              } else {
                throw "`" + name + "` is not a function";
              }
            }

            var res;

            res = tryCallFromScope("_" + context + "_core_" + operator);
            if (res !== false) return res;

            res = tryCallFromScope("_core_" + operator);
            if (res !== false) return res;

            res = tryCallFromScope("_" + context + "_core");
            if (res !== false) return res;

            //############################################################## TODO ###############################################################
            if (context === "get") {

              if (operator === "operatorPlus") {
                var left = codes[0](vm, "get", []);
                var right = codes[1](vm, "get", []);
                if (vm.instanceOf(left, vm.types.typeNumber)) {
                  if (vm.instanceOf(right, vm.types.typeNumber)) {
                    return vm.createObject(vm.types.typeNumber, left.value + right.value);
                  }
                }
                return vm.createObject(vm.types.typeString, vm.toString(left) + vm.toString(right));
              }
              if (operator === "operatorMinus") return vm.createObject(vm.types.typeNumber, codes[0](vm, "get", []).value - codes[1](vm, "get", []).value);
              if (operator === "operatorAsterisk") return vm.createObject(vm.types.typeNumber, codes[0](vm, "get", []).value * codes[1](vm, "get", []).value);
              if (operator === "operatorPercent") return vm.createObject(vm.types.typeNumber, codes[0](vm, "get", []).value % codes[1](vm, "get", []).value);
              if (operator === "operatorSlash") return vm.createObject(vm.types.typeNumber, codes[0](vm, "get", []).value / codes[1](vm, "get", []).value);
              if (operator === "operatorCaret") return vm.createObject(vm.types.typeNumber, Math.pow(codes[0](vm, "get", []).value, codes[1](vm, "get", []).value));
              if (operator === "leftPlus") return vm.createObject(vm.types.typeNumber, codes[0](vm, "get", []).value);
              if (operator === "leftMinus") return vm.createObject(vm.types.typeNumber, -codes[0](vm, "get", []).value);
              if (operator === "leftExclamation") return vm.getBoolean(!vm.toBoolean(codes[0](vm, "get", [])));
              if (operator === "operatorGreater") return vm.getBoolean(codes[0](vm, "get", []).value > codes[1](vm, "get", []).value);
              if (operator === "operatorGreaterEqual") return vm.getBoolean(codes[0](vm, "get", []).value >= codes[1](vm, "get", []).value);
              if (operator === "operatorLess") return vm.getBoolean(codes[0](vm, "get", []).value < codes[1](vm, "get", []).value);
              if (operator === "operatorLessEqual") return vm.getBoolean(codes[0](vm, "get", []).value <= codes[1](vm, "get", []).value);
              if (operator === "operatorEqual2") return vm.getBoolean(codes[0](vm, "get", []).value === codes[1](vm, "get", []).value);
              if (operator === "operatorExclamationEqual") return vm.getBoolean(codes[0](vm, "get", []).value !== codes[1](vm, "get", []).value);
              if (operator === "operatorPipe2") return vm.getBoolean(vm.toBoolean(codes[0](vm, "get", [])) || vm.toBoolean(codes[1](vm, "get", [])));
              if (operator === "operatorAmpersand2") return vm.getBoolean(vm.toBoolean(codes[0](vm, "get", [])) && vm.toBoolean(codes[1](vm, "get", [])));
              if (operator === "operatorTilde") {
                var left = codes[0](vm, "get", []).value;
                var right = codes[1](vm, "get", []).value;
                var array = [];
                for (var i = left; i <= right; i++) {
                  array.push(vm.createObject(vm.types.typeNumber, i));
                }
                return vm.packVector(array);
              }
              if (operator === "enumerateComma") return vm.packVector(codes.map(function(code) { return code(vm, "get", []); }));
              if (operator === "bracketsSquare") {
                return vm.createObject(vm.types.typeArray, vm.unpackVector(codes[0](vm, "get", [])));
              }
              if (operator === "rightbracketsSquare") {
                var value = codes[0](vm, "get", []);
                if (vm.instanceOf(value, vm.types.typeArray)) return value.value[codes[1](vm, "get", []).value] || vm.UNDEFINED;
                throw "Type Error: " + operator + "/" + value.type.value.name;
              }
              if (operator === "leftAtsign") {
                var value = codes[0](vm, "get", []);
                if (vm.instanceOf(value, vm.types.typeArray)) return vm.createObject(vm.types.typeVector, value.value);
                throw "Type Error: " + operator + "/" + value.type.value.name;
              }
              if (operator === "operatorMinus2Greater"
                || operator === "operatorEqual2Greater") 	{
                var minus = operator == "operatorMinus2Greater";
                if (minus) {
                  return vm.packVector(vm.unpackVector(codes[0](vm, "get", [])).map(function(scalar) {
                    return vm.callFunction(vm.createFunction([], codes[1], vm.scope), [scalar]);
                  }));
                } else {
                  return vm.callFunction(vm.createFunction([], codes[1], vm.scope), vm.unpackVector(codes[0](vm, "get", [])));
                }
              }
              if (operator === "operatorMinusGreater"
                || operator === "operatorEqualGreater") 	{
                var minus = operator == "operatorMinusGreater";
                var right = codes[1](vm, "get", []);
                if (minus) {
                  return vm.packVector(vm.unpackVector(codes[0](vm, "get", [])).map(function(scalar) {
                    if (vm.instanceOf(right, vm.types.typeString)) {
                      return vm.callMethodOfBlessed(scalar, right.value, vm.VOID);
                    } else if (vm.instanceOf(right, vm.types.typeFunction)) {
                      return vm.callFunction(right, [scalar]);
                    } else {
                      throw "Type Error: " + right.type.value.name + " != String, Function";
                    }
                  }));
                } else {
                  if (vm.instanceOf(right, vm.types.typeString)) {
                    return vm.callMethodOfBlessed(codes[0](vm, "get", []), right.value, vm.VOID);
                  } else if (vm.instanceOf(right, vm.types.typeFunction)) {
                    return vm.callFunction(right, [codes[0](vm, "get", [])]);
                  } else {
                    throw "Type Error: " + right.type.value.name + " != String, Function";
                  }
                }
                throw "Type Error: " + operator + "/" + right.type.value.name;
              }
              if (operator === "operatorColon") return vm.createObject(vm.types.typeEntry, {
                key: codes[0](vm, "get", []),
                value: codes[1](vm, "get", []),
              });
              if (operator === "leftDollar") return vm.scope.getOrUndefined(codes[0](vm, "get", []).value);
              if (operator === "rightbracketsRound") {
                var value = codes[0](vm, "get", []);
                if (vm.instanceOf(value, vm.types.typeFunction)) return vm.callFunction(value, vm.unpackVector(codes[1](vm, "get", [])));
                throw "Type Error: " + operator + "/" + value.type.value.name;
              }
              if (operator === "statement") {
                var command = codes[0](vm, "get", []);
                if (!vm.instanceOf(command, vm.types.typeKeyword)) throw "Type Error: " + command.type.value.name + " != String";
                if (command.value === "typeof") {
                  var value = codes[1](vm, "get", []);
                  return value.type;
                }
                if (command.value === "var") {
                  var array = codes[1](vm, "arguments").value;
                  array.map(function(item) {
                    if (!vm.instanceOf(item[0], vm.types.typeKeyword)) throw "Type Error: " + item[0].type.value.name + " != Keyword";
                    vm.scope.defineOrSet(item[0].value, vm.UNDEFINED);
                  });
                  return vm.UNDEFINED;
                }
                if (command.value === "console_scope") {
                  console.log(vm.scope);
                  return vm.UNDEFINED;
                }
                if (command.value === "console_log") {
                  var value = codes[1](vm, "get", []);
                  console.log(value);
                  return vm.UNDEFINED;
                }
                if (command.value === "call") {
                  var blessedOperator = codes[1](vm, "get", []);
                  if (!vm.instanceOf(blessedOperator, vm.types.typeString)) throw "Type Error: " + blessedOperator.type.value.name + " != String";
                  var array = codes.slice(2, codes.length).map(function(item) {
                    return vm.createPointer(item, vm.scope);
                  })
                  return vm.callOperator(blessedOperator.value, array.map(function(item) {
                    return function(vm, context, args) {
                      return vm.callPointer(item, context, args);
                    };
                  }), "get", []);
                }
                if (command.value === "instanceof") {
                  if (codes.length != 3) throw "Illegal command argument: " + command.value;
                  var value = codes[1](vm, "get", []);
                  var type = codes[2](vm, "get", []);
                  if (!vm.instanceOf(type, vm.types.typeType)) throw "Type Error: " + type.type.value.name + " != Type";
                  return vm.getBoolean(vm.instanceOf(value, type));
                }
                if (command.value === "length") {
                  var value = codes[1](vm, "get", []);
                  if (vm.instanceOf(value, vm.types.typeArray)) return vm.createObject(vm.types.typeNumber, value.value.length);
                  if (vm.instanceOf(value, vm.types.typeVector)) return vm.createObject(vm.types.typeNumber, value.value.length);
                  if (vm.instanceOf(value, vm.types.typeString)) return vm.createObject(vm.types.typeNumber, value.value.length);
                  throw "Illegal Argument: " + value.type.value;
                }
                if (command.value === "keys") {
                  var value = codes[1](vm, "get", []);
                  if (!vm.instanceOf(value, vm.types.typeHash)) throw "Type Error: " + value.type.value.name + " != Hash";
                  return vm.packVector(Object.keys(value.value).map(function(key) {
                    return vm.createObject(vm.types.typeKeyword, key);
                  }));
                }
                if (command.value === "entry_key") {
                  var value = codes[1](vm, "get", []);
                  if (!vm.instanceOf(value, vm.types.typeEntry)) throw "Type Error: " + value.type.value.name + " != Entry";
                  return value.value.key;
                }
                if (command.value === "entry_value") {
                  var value = codes[1](vm, "get", []);
                  if (!vm.instanceOf(value, vm.types.typeEntry)) throw "Type Error: " + value.type.value.name + " != Entry";
                  return value.value.value;
                }
                if (command.value === "size") {
                  var value = codes[1](vm, "get", []);
                  return vm.createObject(vm.types.typeNumber, vm.unpackVector(value).length);
                }
                if (command.value === "li") {
                  var array = [];
                  for (var i = 1; i < codes.length; i++) {
                    array.push(codes[i](vm, "get", []));
                  }
                  return vm.packVector(array);
                }
                if (command.value === "array") {
                  var array = [];
                  for (var i = 1; i < codes.length; i++) {
                    array.push(codes[i](vm, "get", []));
                  }
                  return vm.createObject(vm.types.typeArray, vm.unpackVector(vm.packVector(array)));
                }
                if (command.value === "throw") {
                  var i = 1, value;
                  value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                  if (!(value !== undefined)) throw "Illegal command argument";
                  var blessedValue = value[3](vm, "get", []);
                  value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                  if (value !== undefined) throw "Illegal command argument: " + value[0];

                  // parse end

                  throw blessedValue;
                }
                if (command.value === "try") {
                  var i = 1, value;
                  value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                  if (!(value !== undefined && value[0] === "curly")) throw "Illegal command argument";
                  var codeTry = value[1];
                  value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                  if (!(value !== undefined && value[0] === "keyword" && value[2] === "catch")) throw "Illegal command argument";
                  value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                  if (!(value !== undefined && value[0] === "round")) throw "Illegal command argument";
                  var arg = value[1](vm, "arguments").value;
                  if (arg.length != 1) throw "Illegal number of arguments: " + arg.length + " != 1";
                  arg = arg[0];
                  arg = [arg[0].value, arg[1]];
                  value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                  if (!(value !== undefined && value[0] === "curly")) throw "Illegal command argument";
                  var codeCatch = value[1];
                  value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                  if (value !== undefined) throw "Illegal command argument: " + value[0];

                  // parse end

                  var blessedResult;
                  try {
                    vm.pushFrame();
                    try {
                      blessedResult = codeTry(vm, "get", []);
                    } finally {
                      vm.popFrame();
                    }
                  } catch (e) {
                    if (vm.instanceOf(e, arg[1])) {
                      vm.pushFrame();
                      vm.scope.defineOrSet(arg[0], e);
                      try {
                        blessedResult = codeCatch(vm, "get", []);
                      } finally {
                        vm.popFrame();
                      }
                    } else {
                      throw e;
                    }
                  }

                  return blessedResult;
                }
                if (command.value === "class") {
                  var i = 1, value;
                  value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                  var blessedName;
                  var isNamed;
                  if (value !== undefined && !((value[0] === "keyword" && value[2] === "extends") || value[0] === "curly")) {
                    blessedName = value[1](vm, "get", []);
                    if (!vm.instanceOf(blessedName, vm.types.typeKeyword)) throw "Type Error: " + blessedName.type.value.name + " != Keyword";
                    value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                    isNamed = true;
                  } else {
                    blessedName = vm.createObject(vm.types.typeKeyword, "Class" + Math.floor(Math.random() * 90000000 + 10000000));
                    isNamed = false;
                  }

                  var blessedExtends;
                  if (value !== undefined && value[0] === "keyword" && value[2] === "extends") {

                    // dummy
                    value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                    blessedExtends = value[1](vm, "get", [vm.createObject(vm.types.typeKeyword, "class")]);
                    if (!vm.instanceOf(blessedExtends, vm.types.typeType)) throw "Type Error: " + blessedExtends.type.value.name + " != Type";
                    value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                  } else {
                    blessedExtends = vm.types.typeHash;
                  }

                  var blessedResult = vm.createType(blessedName.value, blessedExtends);

                  if (value !== undefined && value[0] === "curly") {
                    vm.pushFrame();
                    vm.scope.defineOrSet("class", blessedResult);
                    vm.scope.defineOrSet("super", blessedExtends);
                    try {
                      value[1](vm, "invoke")
                    } finally {
                      vm.popFrame();
                    }
                    value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;
                  }

                  if (value !== undefined) throw "Illegal command argument: " + value[0];

                  // parse end

                  if (isNamed) vm.scope.defineOrSet("class_" + blessedName.value, blessedResult);
                  return blessedResult;
                }
                if (command.value === "new") {
                  var i = 1, value;
                  value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                  var blessedType = value[1](vm, "get", [vm.createObject(vm.types.typeKeyword, "class")]);
                  if (!vm.instanceOf(blessedType, vm.types.typeType)) throw "Type Error: " + blessedType.type.value.name + " != Type";
                  value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                  var blessedArguments = value[1](vm, "get", []);
                  value = codes[i] !== undefined ? codes[i](vm, "contentStatement") : undefined; i++;

                  if (value !== undefined) throw "Illegal command argument: " + value[0];

                  // parse end

                  var blessedsNew = getMethodsOfTypeTree("new", blessedType);

                  for (i = 0; i < blessedsNew.length; i++) {
                     blessedArguments = vm.callFunction(blessedsNew[i], vm.unpackVector(blessedArguments));
                  }

                  blessedArguments.type = blessedType;

                  var blessedsInit = getMethodsOfTypeTree("init", blessedType);
                  for (i = blessedsInit.length - 1; i >= 0; i--) {
                    vm.callFunction(blessedsInit[i], vm.unpackVector(blessedArguments));
                  }

                  return blessedArguments;
                }
                throw "Unknown command: " + command.value;
              }
              if (operator === "leftAmpersand") return vm.createPointer(codes[0], vm.scope);
              if (operator === "bracketsCurly") {
                var hash = {};
                vm.unpackVector(codes[0](vm, "get", [])).forEach(function(item) {
                  if (vm.instanceOf(item, vm.types.typeEntry)) {
                    hash[item.value.key.value] = item.value.value;
                    return;
                  }
                  throw "Type Error: " + item.type.value.name + " is not a Entry";
                });
                return vm.createObject(vm.types.typeHash, hash);
              }
              if (operator === "operatorColon2") {
                var hash = codes[0](vm, "get", [vm.createObject(vm.types.typeKeyword, "class")]);
                var key = codes[1](vm, "get", []);
                if (vm.instanceOf(hash, vm.types.typeHash)) {
                  if (vm.instanceOf(key, vm.types.typeString)) return getProperty(hash.value, key.value) || vm.UNDEFINED;
                  if (vm.instanceOf(key, vm.types.typeKeyword)) return getProperty(hash.value, key.value) || vm.UNDEFINED;
                }
                if (vm.instanceOf(hash, vm.types.typeType)) {
                  if (vm.instanceOf(key, vm.types.typeString)) return getProperty(hash.value.members, key.value) || vm.UNDEFINED;
                  if (vm.instanceOf(key, vm.types.typeKeyword)) return getProperty(hash.value.members, key.value) || vm.UNDEFINED;
                }
                throw "Type Error: " + hash.type.value.name + "[" + key.type.value.name + "]";
              }
              if (operator === "operatorHash") {
                var hash = codes[0](vm, "get", [vm.createObject(vm.types.typeKeyword, "class")]);
                var key = codes[1](vm, "get", []);
                if (vm.instanceOf(hash, vm.types.typeType)) {
                  if (vm.instanceOf(key, vm.types.typeString)) {
                    var value;
                    while (hash != null) {
                      value = getProperty(hash.value.members, key.value) || vm.UNDEFINED;
                      if (!vm.instanceOf(value, vm.types.typeUndefined)) return value;
                      hash = hash.value.supertype;
                    }
                    return vm.UNDEFINED;
                  }
                }
                throw "Type Error: " + hash.type.value.name + "[" + key.type.value.name + "]";
              }
              if (operator === "operatorPeriod") {
                var right = codes[1](vm, "get", []);
                if (vm.instanceOf(right, vm.types.typeString)) {
                  var left = codes[0](vm, "get", []);
                  return vm.createFunction([], function(vm, context, args) {
                      return vm.callMethodOfBlessed(left, right.value, vm.scope.getOrUndefined("_"));
                  }, vm.scope)
                } else if (vm.instanceOf(right, vm.types.typeFunction)) {
                  var left = codes[0](vm, "get", []);
                  return vm.createFunction([], function(vm, context, args) {
                      var array = vm.unpackVector(vm.scope.getOrUndefined("_"));
                      array.unshift(left);
                      return vm.callFunction(right, array);
                  }, vm.scope)
                } else {
                  throw "Type Error: " + right.type.value.name + " != String, Function";
                }
              }
              if (operator === "operatorColonGreater") {
                var array = codes[0](vm, "arguments").value.map(function(item) { return [item[0].value, item[1]]; });
                return vm.createFunction(array, codes[1], vm.scope);
              }
              if (operator === "concatenateLiteral") {
                return vm.createObject(vm.types.typeString, codes.map(function(code) { return vm.toString(code(vm, "get", [])); }).join(""));
              }
              if (operator === "concatenateHereDocument") {
                return vm.createObject(vm.types.typeString, codes.map(function(code) { return vm.toString(code(vm, "get", [])); }).join(""));
              }
              if (operator === "enumerateSemicolon") {
                for (var i = 0; i < codes.length - 1; i++) {
                  codes[i](vm, "invoke");
                }
                return codes[codes.length - 1](vm, "get", []);
              }
              if (operator === "operatorEqual") return codes[0](vm, "set", [codes[1](vm, "get", [])]);
              if (operator === "rightPlus2") {
                var res = codes[0](vm, "get", []);
                codes[0](vm, "set", [vm.createObject(vm.types.typeNumber, res.value + 1)]);
                return res;
              }
              if (operator === "rightMinus2") {
                var res = codes[0](vm, "get", []);
                codes[0](vm, "set", [vm.createObject(vm.types.typeNumber, res.value - 1)]);
                return res;
              }
              if (operator === "operatorQuestionColon") {
                var res = codes[0](vm, "get", []);
                return vm.toBoolean(res) ? res : codes[1](vm, "get", []);
              }
              if (operator === "operatorQuestion2") {
                var res = codes[0](vm, "get", []);
                return !vm.instanceOf(res, vm.types.typeUndefined) ? res : codes[1](vm, "get", []);
              }
              if (operator === "hereDocumentFunction") {
                var value = codes[0](vm, "get", [vm.createObject(vm.types.typeKeyword, "decoration"), vm.createObject(vm.types.typeKeyword, "function")]);
                if (vm.instanceOf(value, vm.types.typeFunction)) return vm.callFunction(value, [vm.createPointer(codes[1], vm.scope), vm.createPointer(codes[2], vm.scope)]);
                throw "Type Error: " + operator + "/" + value.type.value.name;
              }
              if (operator === "leftMultibyte") {
                return vm.callOperator("leftMultibyte_" + codes[0](vm, "get", []).value, [codes[1]], context, args);
              }
              if (operator === "operatorMultibyte") {
                return vm.callOperator("operatorMultibyte_" + codes[1](vm, "get", []).value, [codes[0], codes[2]], context, args);
              }
              if (operator === "leftWord") {
                var value = codes[0](vm, "get", [vm.createObject(vm.types.typeKeyword, "leftWord"), vm.createObject(vm.types.typeKeyword, "word"), vm.createObject(vm.types.typeKeyword, "function")]);
                if (vm.instanceOf(value, vm.types.typeFunction)) return vm.callFunction(value, [codes[1](vm, "get", [])]);
                throw "Type Error: " + operator + "/" + value.type.value.name;
              }
              if (operator === "operatorWord") {
                var value = codes[1](vm, "get", [vm.createObject(vm.types.typeKeyword, "operatorWord"), vm.createObject(vm.types.typeKeyword, "word"), vm.createObject(vm.types.typeKeyword, "function")]);
                if (vm.instanceOf(value, vm.types.typeFunction)) return vm.callFunction(value, [codes[0](vm, "get", []), codes[2](vm, "get", [])]);
                throw "Type Error: " + operator + "/" + value.type.value.name;
              }
              if (operator === "rightComposite") {
                var value = codes[1](vm, "get", [vm.createObject(vm.types.typeKeyword, "rightComposite"), vm.createObject(vm.types.typeKeyword, "composite"), vm.createObject(vm.types.typeKeyword, "function")]);
                if (vm.instanceOf(value, vm.types.typeFunction)) return vm.callFunction(value, [codes[0](vm, "get", [])]);
                throw "Type Error: " + operator + "/" + value.type.value.name;
              }
              if (operator === "operatorComposite") {
                var value = codes[1](vm, "get", [vm.createObject(vm.types.typeKeyword, "operatorComposite"), vm.createObject(vm.types.typeKeyword, "composite"), vm.createObject(vm.types.typeKeyword, "function")]);
                if (vm.instanceOf(value, vm.types.typeFunction)) return vm.callFunction(value, [codes[0](vm, "get", []), codes[2](vm, "get", [])]);
                throw "Type Error: " + operator + "/" + value.type.value.name;
              }
            } else if (context === "set") {
              if (operator === "leftDollar") {
                var value = args[0];
                vm.scope.setOrDefine(codes[0](vm, "get", []).value, value);
                return value;
              }
              if (operator === "operatorColon2") {
                var hash = codes[0](vm, "get", [vm.createObject(vm.types.typeKeyword, "class")]);
                var key = codes[1](vm, "get", []);
                if (vm.instanceOf(hash, vm.types.typeHash)) {
                  if (vm.instanceOf(key, vm.types.typeString)) return hash.value[key.value] = args[0];
                  if (vm.instanceOf(key, vm.types.typeKeyword)) return hash.value[key.value] = args[0];
                }
                if (vm.instanceOf(hash, vm.types.typeType)) {
                  if (vm.instanceOf(key, vm.types.typeString)) return hash.value.members[key.value] = args[0];
                  if (vm.instanceOf(key, vm.types.typeKeyword)) return hash.value.members[key.value] = args[0];
                }
                throw "Type Error: " + hash.type.value.name + "[" + key.type.value.name + "]";
              }
            } else if (context === "invoke") {
              if (operator === "bracketsCurly") {
                codes[0](vm, "invoke");
                return;
              }
              vm.callOperator(operator, codes, "get", []);
              return;
            } else if (context === "contentStatement") {
              if (operator === "bracketsRound") return ["round", codes[0], undefined, createCodeFromMethod(operator, codes)];
              if (operator === "bracketsSquare") return ["square", codes[0], undefined, createCodeFromMethod(operator, codes)];
              if (operator === "bracketsCurly") return ["curly", codes[0], undefined, createCodeFromMethod(operator, codes)];
              return ["normal", createCodeFromMethod(operator, codes), undefined, createCodeFromMethod(operator, codes)];
            } else if (context === "arguments") {
              if (operator === "leftDollar") return vm.createObject(vm.types.typeObject, [[codes[0](vm, "argumentName"), vm.types.typeValue]]);
              if (operator === "operatorColon") return vm.createObject(vm.types.typeObject, [[codes[0](vm, "argumentName"), codes[1](vm, "get", [vm.createObject(vm.types.typeKeyword, "class")])]]);
              if (operator === "enumerateComma") return vm.createObject(vm.types.typeObject, codes.map(function(code) { return code(vm, "argument").value; }));
            } else if (context === "argument") {
              if (operator === "leftDollar") return vm.createObject(vm.types.typeObject, [codes[0](vm, "argumentName"), vm.types.typeValue]);
              if (operator === "operatorColon") return vm.createObject(vm.types.typeObject, [codes[0](vm, "argumentName"), codes[1](vm, "get", [vm.createObject(vm.types.typeKeyword, "class")])]);
            } else if (context === "argumentName") {
              if (operator === "leftDollar") return codes[0](vm, "argumentName");
            }

            if (operator === "leftAsterisk") {
              var value = codes[0](vm, "get", []);
              if (vm.instanceOf(value, vm.types.typePointer)) return vm.callPointer(value, context, args);
              throw "Type Error: " + operator + "/" + value.type.value.name;
            }
            if (operator === "ternaryQuestionColon") return codes[vm.toBoolean(codes[0](vm, "get", [])) ? 1 : 2](vm, context, args);
            if (operator === "bracketsRound") return vm.callInFrame(codes[0], vm, context, args);
            //############################################################## TODO ###############################################################

            var blessedsArgs = codes.map(function(code) { return code(vm, "get", []); });
            blessedsArgs.unshift(vm.createObject(vm.types.typeString, context));
            var blessedsTypes = blessedsArgs.map(function(blessed) { return blessed.type; });

            res = vm.tryCallMethodOfOperator("_" + context + "_" + operator, blessedsArgs);
            if (res !== false) return res;

            res = vm.tryCallMethodOfOperator("_" + operator, blessedsArgs);
            if (res !== false) return res;

            throw "Unknown operator: " + operator + "/" + context;
          };
          this.toString = function(value) {
            vm.consumeLoopCapacity();
            if (vm.instanceOf(value, vm.types.typeValue)) {
              return "" + vm.callMethodOfBlessed(value, "toString", vm.VOID).value;
            } else {
              return "" + value;
            }
          };
          this.toNative = function(value) {
            vm.consumeLoopCapacity();
            var vm = this;
            if (vm.instanceOf(value, vm.types.typeVector)) {
              return value.value.map(function(scalar) { return vm.toNative(scalar); });
            }
            if (vm.instanceOf(value, vm.types.typeArray)) {
              return value.value.map(function(scalar) { return vm.toNative(scalar); });
            }
            return value.value;
          };
          this.toBoolean = function(value) {
            vm.consumeLoopCapacity();
            if (vm.instanceOf(value, vm.types.typeValue)) {
              return !!vm.callMethodOfBlessed(value, "toBoolean", vm.VOID).value;
            } else {
              return !!value;
            }
          };
          this.createLiteral = function(type, value, context, args) {
            vm.consumeLoopCapacity();
            if (context === "get") {
              if (type === "Integer") return vm.createObject(vm.types.typeNumber, value);
              if (type === "Float") return vm.createObject(vm.types.typeNumber, value);
              if (type === "String") return vm.createObject(vm.types.typeString, value);
              if (type === "Affix" || type === "Identifier") {
                if (value === "true") return vm.TRUE;
                if (value === "false") return vm.FALSE;
                if (value === "undefined") return vm.UNDEFINED;
                if (value === "null") return vm.NULL;
                if (value === "Infinity") return vm.createObject(vm.types.typeNumber, Infinity);
                if (value === "NaN") return vm.createObject(vm.types.typeNumber, NaN);

                if (args.length > 0) {
                  var accesses = args.map(function(arg) { return arg.value; });
                  var variable;

                  for (var i = 0; i < accesses.length; i++) {
                    variable = vm.scope.getOrUndefined(accesses[i] + "_" + value);
                    if (!vm.instanceOf(variable, vm.types.typeUndefined)) return variable;
                  }

                  variable = vm.scope.getOrUndefined(value);
                  if (!vm.instanceOf(variable, vm.types.typeUndefined)) return variable;

                }
                return vm.createObject(vm.types.typeKeyword, value);
              }
              if (type === "Void") return vm.VOID;
              if (type === "Boolean") return vm.getBoolean(value);
            } else if (context === "invoke") {
              return vm.createLiteral(type, value, "get", []);
            } else if (context === "contentStatement") {
              if (type === "Identifier") return ["keyword", createCodeFromLiteral(type, value), value, createCodeFromLiteral(type, value)];
              return ["normal", createCodeFromLiteral(type, value), undefined, createCodeFromLiteral(type, value)];
            } else if (context === "arguments") {
              if (type === "Identifier") return vm.createObject(vm.types.typeObject, [[vm.createObject(vm.types.typeKeyword, value), vm.types.typeValue]]);
              if (type === "Void") return vm.createObject(vm.types.typeObject, []);
            } else if (context === "argument") {
              if (type === "Identifier") return vm.createObject(vm.types.typeObject, [vm.createObject(vm.types.typeKeyword, value), vm.types.typeValue]);
            } else if (context === "argumentName") {
              if (type === "Identifier") return vm.createObject(vm.types.typeKeyword, value);
            }
            throw "Unknown Literal Type: " + context + "/" + type;
          };
        }
        VMStandard.prototype.pushScope = function() {
          this.scope = new Scope(this.scope, false, this.UNDEFINED);
        };
        VMStandard.prototype.pushFrame = function() {
          this.scope = new Scope(this.scope, true, this.UNDEFINED);
        };
        VMStandard.prototype.popFrame = function() {
          this.scope = this.scope.getParentFrame();
        };
        VMStandard.prototype.pushStack = function(scope2) {
          this.stack.push(this.scope);
          this.scope = scope2;
        };
        VMStandard.prototype.popStack = function() {
          this.scope = this.stack.pop();
        };

        VMStandard.prototype.createObject = function(type, value) {
          return {
            type: type,
            value: value,
          };
        };
        VMStandard.prototype.getBoolean = function(value) {
          return value ? this.TRUE : this.FALSE;
        };
        VMStandard.prototype.createException = function(message) {
          return this.createObject(this.types.typeException, {
            message: message,
          });
        };
        VMStandard.prototype.createFunction = function(args, code, scope) {
          return this.createObject(this.types.typeFunction, {
            args: args,
            code: code,
            scope: scope,
          });
        };
        VMStandard.prototype.createPointer = function(code, scope) {
          return this.createObject(this.types.typePointer, {
            code: code,
            scope: scope,
          });
        };
        VMStandard.prototype.createType = function(name, supertype) {
          return this.createObject(this.types.typeType, {
            name: name,
            supertype: supertype,
            members: {},
          });
        };
        VMStandard.prototype.packVector = function(array) {
          var vm = this;

          function visitScalar(array, blessed)
          {
            if (vm.instanceOf(blessed, vm.types.typeVector)) {
              for (var i = 0; i < blessed.value.length; i++) {
                visitScalar(array, blessed.value[i]);
              }
            } else {
              array.push(blessed);
            }
          }

          var array2 = [];
          array.forEach(function(item) { visitScalar(array2, item); });
          if (array2.length == 1) return array2[0];
          return this.createObject(this.types.typeVector, array2);
        };
        VMStandard.prototype.unpackVector = function(blessed) {
          if (this.instanceOf(blessed, this.types.typeVector)) return blessed.value.concat();
          return [blessed];
        };
        VMStandard.prototype.callInFrame = function(code, vm, context, args) {
          this.pushFrame();
          var res;
          try {
            res = code(this, context, args);
          } finally {
            this.popFrame();
          }
          return res;
        };
        VMStandard.prototype.callPointer = function(blessedPointer, context, args) {
          this.pushStack(blessedPointer.value.scope);
          var res;
          try {
            res = blessedPointer.value.code(this, context, args);
          } finally {
            this.popStack();
          }
          return res;
        };
        VMStandard.prototype.isCallableFunction = function(blessedFunction, blessedsArgs) {
          for (var i = 0; i < blessedFunction.value.args.length; i++) {
            if (!this.instanceOf(blessedsArgs[i] || this.UNDEFINED, blessedFunction.value.args[i][1])) return false;
          }
          return true;
        };
        VMStandard.prototype.callFunction = function(blessedFunction, blessedsArgs) {
          this.pushStack(blessedFunction.value.scope);
          this.pushFrame();
          for (var i = 0; i < blessedFunction.value.args.length; i++) {
            this.scope.defineOrSet(blessedFunction.value.args[i][0], blessedsArgs[i] || this.UNDEFINED);
          }
          this.scope.defineOrSet("_", this.packVector(blessedsArgs.slice(i, blessedsArgs.length)));
          var res;
          try {
            res = blessedFunction.value.code(this, "get", []);
          } finally {
            this.popFrame();
            this.popStack();
          }
          return res;
        };
        VMStandard.prototype.instanceOf = function(blessed, blessedType2) {
          if ((typeof blessed) !== "object") return false;
          if (blessed.type === undefined) return false;

          var blessedType = blessed.type;

          while (blessedType !== null) {
            if (blessedType == blessedType2) return true;
            blessedType = blessedType.value.supertype;
          }

          return false;
        };
        VMStandard.prototype.getMethodOfCall = function(name, blessedsTypes, predicate) {
          var res;

          for (var i = 0; i < blessedsTypes.length; i++) {
            var blessedType = blessedsTypes[i];
            while (blessedType !== null) {

              res = getProperty(blessedType.value.members, name) || this.UNDEFINED;
              if (this.instanceOf(res, this.types.typeFunction)) if (predicate(res)) return res;

              blessedType = blessedType.value.supertype;
            }
          }

          res = this.scope.getOrUndefined("method_" + name);
          if (this.instanceOf(res, this.types.typeFunction)) if (predicate(res)) return res;

          res = this.scope.getOrUndefined("function_" + name);
          if (this.instanceOf(res, this.types.typeFunction)) if (predicate(res)) return res;

          res = this.scope.getOrUndefined(name);
          if (this.instanceOf(res, this.types.typeFunction)) if (predicate(res)) return res;

          return this.UNDEFINED;
        };
        VMStandard.prototype.tryCallMethod = function(name, blessedsTypes, blessedsArgs) {
          var vm = this;
          var res = this.getMethodOfCall(name, blessedsTypes, function(blessedFunction) {
            return vm.isCallableFunction(blessedFunction, blessedsArgs);
          });
          if (this.instanceOf(res, this.types.typeFunction)) {
            return this.callFunction(res, blessedsArgs);
          }
          return false;
        };
        VMStandard.prototype.tryCallMethodOfOperator = function(name, blessedsArgs) {
          return this.tryCallMethod(name, blessedsArgs.map(function(blessedArg) { return blessedArg.type; }), blessedsArgs);
        };
        VMStandard.prototype.callMethod = function(name, blessedsTypes, blessedsArgs) {
          var vm = this;
          var res = this.getMethodOfCall(name, blessedsTypes, function(blessedFunction) {
            return vm.isCallableFunction(blessedFunction, blessedsArgs);
          });
          if (this.instanceOf(res, this.types.typeFunction)) {
            return this.callFunction(res, blessedsArgs);
          }
          throw "No such method: " + name + "(" + blessedsArgs.map(function(blessedArg) { return blessedArg.type.value.name; }).join(", ") + ")/"
            + blessedsTypes.map(function(blessedType) { return blessedType.value.name; }).join(", ");
        };
        VMStandard.prototype.callMethodOfBlessed = function(blessedObject, name, blessedArgs) {
          var blesseds = this.unpackVector(blessedArgs);
          blesseds.unshift(blessedObject);
          return this.callMethod(name, [blessedObject.type], blesseds);
        };

        VMStandard.prototype.initBootstrap = function() {
          var vm = this;
          var listeners = [];

          function createConstructor(blessedType)
          {
            return function() {
              blessedType.value.members["new"] = vm.createFunction([["type", vm.types.typeValue]], function(vm, context) {
                var blessedValue = vm.scope.getOrUndefined("type");
                if (vm.instanceOf(blessedValue, blessedType)) return blessedValue;
                throw "Construct Error: Expected " + blessedType.value.name + " but " + blessedValue.type.value.name;
              }, vm.scope);
            };
          }

          this.types = {};
          this.types.typeType = this.createType("Type", null); // 先頭でなければcreateTypeが失敗する
          this.types.typeType.type = this.types.typeType;

           this.types.typeValue = this.createType("Value", null);
             this.types.typeUndefined = this.createType("Undefined", this.types.typeValue);
             this.types.typeDefined = this.createType("Defined", this.types.typeValue);
               this.types.typeType.value.supertype = this.types.typeDefined;
               this.types.typeNull = this.createType("Null", this.types.typeDefined);
               this.types.typeNumber = this.createType("Number", this.types.typeDefined); listeners.push(createConstructor(this.types.typeNumber));
               this.types.typeString = this.createType("String", this.types.typeDefined); listeners.push(createConstructor(this.types.typeString));
                 this.types.typeKeyword = this.createType("Keyword", this.types.typeString);
               this.types.typeBoolean = this.createType("Boolean", this.types.typeDefined); listeners.push(createConstructor(this.types.typeBoolean));
               this.types.typeFunction = this.createType("Function", this.types.typeDefined); listeners.push(createConstructor(this.types.typeFunction));
               // this.types.typeFunctionNative = this.createType("FunctionNative", this.types.typeDefined); TODO
               this.types.typePointer = this.createType("Pointer", this.types.typeDefined); listeners.push(createConstructor(this.types.typePointer));
               this.types.typeArray = this.createType("Array", this.types.typeDefined); listeners.push(createConstructor(this.types.typeArray));
                 this.types.typeVector = this.createType("Vector", this.types.typeArray);
               this.types.typeObject = this.createType("Object", this.types.typeDefined); listeners.push(createConstructor(this.types.typeObject));
                 this.types.typeHash = this.createType("Hash", this.types.typeObject);
                 this.types.typeEntry = this.createType("Entry", this.types.typeObject);
                 this.types.typeException = this.createType("Exception", this.types.typeObject);

          this.UNDEFINED = this.createObject(this.types.typeUndefined, undefined);
          this.NULL = this.createObject(this.types.typeNull, null);
          this.VOID = this.packVector([]);
          this.TRUE = this.createObject(this.types.typeBoolean, true);
          this.FALSE = this.createObject(this.types.typeBoolean, false);

          this.scope = new Scope(null, true, vm.UNDEFINED);
          this.stack = [];

          listeners.map(function(a) { a(); })
        };

        VMStandard.prototype.initLibrary = function() {
          var vm = this;

          vm.types.typeValue.value.members["toString"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            return vm.createObject(vm.types.typeString, "<" + value.type.value.name + ">");
          }, vm.scope);
          vm.types.typeNumber.value.members["toString"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            return vm.createObject(vm.types.typeString, "" + value.value);
          }, vm.scope);
          vm.types.typeString.value.members["toString"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            return vm.createObject(vm.types.typeString, value.value);
          }, vm.scope);
          vm.types.typeBoolean.value.members["toString"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            return vm.createObject(vm.types.typeString, "" + value.value);
          }, vm.scope);
          vm.types.typeArray.value.members["toString"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            return vm.createObject(vm.types.typeString, "[" + value.value.map(function(scalar) { return vm.toString(scalar); }).join(", ") + "]");
          }, vm.scope);
          vm.types.typeHash.value.members["toString"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            return vm.createObject(vm.types.typeString, "{" + Object.keys(value.value).map(function(key) {
              return key + ": " + vm.toString(value.value[key]);
            }).join(", ") + "}");
          }, vm.scope);
          vm.types.typeEntry.value.members["toString"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            return vm.createObject(vm.types.typeString, vm.toString(value.value.key) + ": " + vm.toString(value.value.value));
          }, vm.scope);
          vm.types.typeVector.value.members["toString"] = vm.createFunction([], function(vm, context) {
            var value = vm.scope.getOrUndefined("_");
            if (value.value.length == 0) return vm.createObject(vm.types.typeString, "<Void>");
            return vm.createObject(vm.types.typeString, value.value.map(function(scalar) { return vm.toString(scalar); }).join(", "));
          }, vm.scope);
          vm.types.typeType.value.members["toString"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            return vm.createObject(vm.types.typeString, "<Type: " + value.value.name + ">");
          }, vm.scope);
          vm.types.typeFunction.value.members["toString"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            if (value.value.args.length === 0) return vm.createObject(vm.types.typeString, "<Function>");
            return vm.createObject(vm.types.typeString, "<Function: " + value.value.args.map(function(arg) {
              if ((typeof arg) === "string") { // TODO
                return arg;
              } else {
                return "" + arg[0] + " : " + arg[1].value.name;
              }
            }).join(", ") + ">");
          }, vm.scope);
          vm.types.typeException.value.members["toString"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            return vm.createObject(vm.types.typeString, "<Exception: '" + value.value.message + "'>");
          }, vm.scope);

          vm.types.typeValue.value.members["toBoolean"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            return vm.TRUE;
          }, vm.scope);
          vm.types.typeUndefined.value.members["toBoolean"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            return vm.FALSE;
          }, vm.scope);
          vm.types.typeNull.value.members["toBoolean"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            return vm.FALSE;
          }, vm.scope);
          vm.types.typeNumber.value.members["toBoolean"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            return vm.getBoolean(value.value != 0);
          }, vm.scope);
          vm.types.typeString.value.members["toBoolean"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            return vm.getBoolean(value.value !== "");
          }, vm.scope);
          vm.types.typeBoolean.value.members["toBoolean"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            return value;
          }, vm.scope);
          vm.types.typeArray.value.members["toBoolean"] = vm.createFunction([["this", vm.types.typeValue]], function(vm, context) {
            var value = vm.scope.getOrUndefined("this");
            return vm.getBoolean(value.value.length > 0);
          }, vm.scope);

          {
            var hash = {};
            Object.keys(vm.types).forEach(function(key) {
              hash[vm.types[key].value.name] = vm.types[key];
            });
            vm.scope.setOrDefine("fluorite", vm.createObject(vm.types.typeHash, {
              "type": vm.createObject(vm.types.typeHash, hash),
            }));
          }
          Object.keys(vm.types).forEach(function(key) {
            vm.scope.setOrDefine("class_" + vm.types[key].value.name, vm.types[key]);
          });
          function createNativeBridge(func, argumentCount)
          {
            if (argumentCount == 0) {
              return vm.createFunction([], function(vm, context) {
                return vm.createObject(vm.types.typeNumber, func());
              }, vm.scope);
            } else if (argumentCount == 1) {
              return vm.createFunction([["x", vm.types.typeValue]], function(vm, context) {
                return vm.createObject(vm.types.typeNumber, func(vm.scope.getOrUndefined("x").value));
              }, vm.scope);
            } else if (argumentCount == 2) {
              return vm.createFunction([["x", vm.types.typeValue], ["y", vm.types.typeValue]], function(vm, context) {
                return vm.createObject(vm.types.typeNumber, func(vm.scope.getOrUndefined("x").value, vm.scope.getOrUndefined("y").value));
              }, vm.scope);
            } else {
              throw "TODO"; // TODO
            }
          }
          vm.scope.setOrDefine("Math", vm.createObject(vm.types.typeHash, {
            "PI": vm.createObject(vm.types.typeNumber, Math.PI),
            "E": vm.createObject(vm.types.typeNumber, Math.E),
            "abs": createNativeBridge(Math.abs, 1),
            "sin": createNativeBridge(Math.sin, 1),
            "cos": createNativeBridge(Math.cos, 1),
            "tan": createNativeBridge(Math.tan, 1),
            "asin": createNativeBridge(Math.asin, 1),
            "acos": createNativeBridge(Math.acos, 1),
            "atan": createNativeBridge(Math.atan, 1),
            "atan2": createNativeBridge(Math.atan2, 2),
            "log": createNativeBridge(Math.log, 1),
            "ceil": createNativeBridge(Math.ceil, 1),
            "floor": createNativeBridge(Math.floor, 1),
            "exp": createNativeBridge(Math.exp, 1),
            "pow": createNativeBridge(Math.pow, 2),
            "random": createNativeBridge(Math.random, 0),
            "randomBetween": createNativeBridge(function(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }, 2),
            "sqrt": createNativeBridge(Math.sqrt, 1),
          }));

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
          vm.scope.setOrDefine("rightComposite_d", vm.createFunction([["count", vm.types.typeValue]], function(vm, context) {
            var count = vm.scope.getOrUndefined("count");
            if (!vm.instanceOf(count, vm.types.typeNumber)) throw "Illegal argument[0]: " + count.type.value.name + " != Number";
            if (count.value > 20) throw vm.createException("Illegal argument[0]: " + count.value + " > 20");
            return vm.createObject(vm.types.typeNumber, dice(count.value, 6));
          }, vm.scope));
          vm.scope.setOrDefine("function_d", vm.createFunction([["count", vm.types.typeValue], ["faces", vm.types.typeValue]], function(vm, context) {
            var count = vm.scope.getOrUndefined("count");
            var faces = vm.scope.getOrUndefined("faces");
            if (!vm.instanceOf(count, vm.types.typeNumber)) throw "Illegal argument[0]: " + count.type.value.name + " != Number";
            if (count.value > 20) throw vm.createException("Illegal argument[0]: " + count.value + " > 20");
            if (!vm.instanceOf(faces, vm.types.typeNumber)) throw "Illegal argument[1]: " + faces.type.value.name + " != Number";
            return vm.createObject(vm.types.typeNumber, dice(count.value, faces.value));
          }, vm.scope));

          vm.scope.setOrDefine("leftMultibyte_√", vm.createFunction([["x", vm.types.typeValue]], function(vm, context) {
            var x = vm.scope.getOrUndefined("x");
            if (!vm.instanceOf(x, vm.types.typeNumber)) throw "Illegal argument[0]: " + x.type.value.name + " != Number";
            return vm.createObject(vm.types.typeNumber, Math.sqrt(x.value));
          }, vm.scope));
          vm.scope.setOrDefine("function_join", vm.createFunction([["separator", vm.types.typeValue]], function(vm, context) {
            var separator = vm.scope.getOrUndefined("separator");
            var vector = vm.scope.getOrUndefined("_");
            return vm.createObject(vm.types.typeString, vm.unpackVector(vector).map(function(blessed) {
              return vm.toString(blessed);
            }).join(separator.value));
          }, vm.scope));
          vm.scope.setOrDefine("function_join1", vm.createFunction([], function(vm, context) {
            var vector = vm.scope.getOrUndefined("_");
            return vm.createObject(vm.types.typeString, vm.unpackVector(vector).map(function(blessed) {
              return vm.toString(blessed);
            }).join(""));
          }, vm.scope));
          vm.scope.setOrDefine("function_join2", vm.createFunction([], function(vm, context) {
            var vector = vm.scope.getOrUndefined("_");
            return vm.createObject(vm.types.typeString, vm.unpackVector(vector).map(function(blessed) {
              return vm.toString(blessed);
            }).join(", "));
          }, vm.scope));
          vm.scope.setOrDefine("function_join3", vm.createFunction([], function(vm, context) {
            var vector = vm.scope.getOrUndefined("_");
            return vm.createObject(vm.types.typeString, vm.unpackVector(vector).map(function(blessed) {
              return vm.toString(blessed);
            }).join("\n"));
          }, vm.scope));
          vm.scope.setOrDefine("function_sum", vm.createFunction([], function(vm, context) {
            var value = 0;
            vm.unpackVector(vm.scope.getOrUndefined("_")).forEach(function(blessed) {
              value += blessed.value;
            });
            return vm.createObject(vm.types.typeNumber, value);
          }, vm.scope));
          vm.scope.setOrDefine("function_average", vm.createFunction([], function(vm, context) {
            var array = vm.unpackVector(vm.scope.getOrUndefined("_"));
            if (array.length == 0) return vm.UNDEFINED;
            var value = 0;
            array.forEach(function(blessed) {
              value += blessed.value;
            });
            return vm.createObject(vm.types.typeNumber, value / array.length);
          }, vm.scope));
          vm.scope.setOrDefine("function_count", vm.createFunction([], function(vm, context) {
            return vm.createObject(vm.types.typeNumber, vm.unpackVector(vm.scope.getOrUndefined("_")).length);
          }, vm.scope));
          vm.scope.setOrDefine("function_and", vm.createFunction([], function(vm, context) {
            var value = true;
            vm.unpackVector(vm.scope.getOrUndefined("_")).forEach(function(blessed) {
              value = value && blessed.value;
            });
            return vm.getBoolean(value);
          }, vm.scope));
          vm.scope.setOrDefine("function_or", vm.createFunction([], function(vm, context) {
            var value = false;
            vm.unpackVector(vm.scope.getOrUndefined("_")).forEach(function(blessed) {
              value = value || blessed.value;
            });
            return vm.getBoolean(value);
          }, vm.scope));
          vm.scope.setOrDefine("function_max", vm.createFunction([], function(vm, context) {
            var array = vm.unpackVector(vm.scope.getOrUndefined("_"));
            if (array.length == 0) return vm.UNDEFINED;
            var value = array[0].value;
            for (var i = 1; i < array.length; i++) {
              if (value < array[i].value) value = array[i].value;
            }
            return vm.createObject(vm.types.typeNumber, value);
          }, vm.scope));
          vm.scope.setOrDefine("function_min", vm.createFunction([], function(vm, context) {
            var array = vm.unpackVector(vm.scope.getOrUndefined("_"));
            if (array.length == 0) return vm.UNDEFINED;
            var value = array[0].value;
            for (var i = 1; i < array.length; i++) {
              if (value > array[i].value) value = array[i].value;
            }
            return vm.createObject(vm.types.typeNumber, value);
          }, vm.scope));
        };

        return VMStandard;
      })();
    } else {
      throw "Unknown VM name: " + name;
    }
  }

}

ExpressionPlain
  = main:Expression {
      var vm = new (getVM("standard"))();
      var texts = [main[0]];
      var i;
      for (i = 1; i < main.length; i += 2) {
        try {
          texts.push(vm.toString(main[i][1](vm, "get", [])));
        } catch (e) {
          try {
            texts.push("[Error: " + vm.toString(e) + "][" + main[i][0] + "]");
          } catch (e) {
            texts.push("[Error: " + e + "][" + main[i][0] + "]");
          }
        }
        texts.push(main[i + 1]);
      }
      return texts.join("");
    }

VMFactory
  = name:([a-zA-Z0-9_]+ { return text(); }) { return getVM(name); }

Expression
  = Message

Message
  = ("#!" [^\n\r]* ([\r\n] / "\r\n"))? head:MessageText tail:("\\" _ MessageFormula _ "\\" MessageText)* {
      var result = [head], i;

      for (i = 0; i < tail.length; i++) {
        result.push(tail[i][2]);
        result.push(tail[i][5]);
      }

      return result;
    }

MessageText
  = main:(
      [^\\]
    / "\\\\" { return "\\"; }
    )* { return main.join(""); }

MessageFormula
  = main:Formula {
      return [text(), main];
    }

Formula
  = Line

Line
  = head:Arrows tail:(_ (";") _ Arrows)* (_ ";")? { return enumerate(head, tail, "Semicolon"); }

Arrows
  = head:(
      (
        main:Vector _ "-->" _ { return ["Minus2Greater", main]; }
      / main:Vector _ "->" _ { return ["MinusGreater", main]; }
      / main:Vector _ "==>" _ { return ["Equal2Greater", main]; }
      / main:Vector _ "=>" _ { return ["EqualGreater", main]; }
      )+
    / main:Vector _ ":>" _ { return [["ColonGreater", main]]; }
    / main:Vector _ "=" _ { return [["Equal", main]]; }
    )* tail:Vector {
      var result = tail, i, j;
      for (i = head.length - 1; i >= 0; i--) {
        var result2 = head[i][0][1];
        for (j = 1; j < head[i].length; j++) {
          result2 = createCodeFromMethod("operator" + head[i][j - 1][0], [result2, head[i][j][1]]);
        }
        result = createCodeFromMethod("operator" + head[i][head[i].length - 1][0], [result2, result]);
      }
      return result;
    }

Vector
  = head:Entry tail:(_ (",") _ Entry)* (_ ",")? { return enumerate(head, tail, "Comma"); }

Entry
  = head:Iif tail:(_ (
      ":" { return "Colon"; }
    ) _ Iif)* { return operatorLeft(head, tail); }

Iif
  = head:Range _ "?" _ body:Iif _ ":" _ tail:Iif { return createCodeFromMethod("ternaryQuestionColon", [head, body, tail]); }
  / head:Range _ "?:" _ tail:Iif { return createCodeFromMethod("operatorQuestionColon", [head, tail]); }
  / head:Range _ "??" _ tail:Iif { return createCodeFromMethod("operatorQuestion2", [head, tail]); }
  / Range

Range
  = head:Or tail:(_ (
      "~" { return "Tilde"; }
    / ".." { return "Period2"; }
    ) _ Or)* { return operatorLeft(head, tail); }

Or
  = head:And tail:(_ (
      "||" { return "Pipe2"; }
    / "|" { return "Pipe"; }
    ) _ And)* { return operatorLeft(head, tail); }

And
  = head:Compare tail:(_ (
      "&&" { return "Ampersand2"; }
    / "&" { return "Ampersand"; }
    ) _ Compare)* { return operatorLeft(head, tail); }

Compare
  = head:Shift tail:(_ (
      ">=" { return "GreaterEqual"; }
    / ">" { return "Greater"; }
    / "<=" { return "LessEqual"; }
    / "<" { return "Less"; }
    / "!=" { return "ExclamationEqual"; }
    / "==" { return "Equal2"; }
    ) _ Shift)* {
      if (tail.length == 0) return head;
      var codes = [], left = head, right, i;

      for (i = 0; i < tail.length; i++) {
        right = tail[i][3];
        codes.push(createCodeFromMethod("operator" + tail[i][1], [left, right]));
        left = right;
      }

      return function(vm, context, args) {
        if (context === "get") {
          var array = codes.map(function(code) { return code(vm, "get", []); });

          for (var i = 0; i < array.length; i++) {
            if (!vm.toBoolean(array[i])) return vm.createLiteral("Boolean", false, context, args);
          }

          return vm.createLiteral("Boolean", true, context, args);
        } else {
          throw "Unknown context: " + context;
        }
      };
    }

Shift
  = head:Add tail:(_ (
      "<<" { return "Less2"; }
    / ">>" { return "Greater2"; }
    ) _ Term)* { return operatorLeft(head, tail); }

Add
  = head:Term tail:(_ (
      "+" { return "Plus"; }
    / "-" { return "Minus"; }
    ) _ Term)* { return operatorLeft(head, tail); }

Term
  = head:Power tail:(_ (
      "*" { return "Asterisk"; }
    / "/" { return "Slash"; }
    / "%" { return "Percent"; }
    ) _ Power)* { return operatorLeft(head, tail); }

Power
  = head:(MultibyteOperating _ (
      "^" { return "Caret"; }
    ) _)* tail:MultibyteOperating { return operatorRight(head, tail); }

MultibyteOperating
  = head:Left tail:(_ (
      CharacterMultibyteSymbol { return ["Multibyte", createCodeFromLiteral("Identifier", text())]; }
    / "`" _ main:Formula _ "`" { return ["Word", main]; }
    ) _ Left)* { return operatorLeft(head, tail); }

Left
  = head:((
      "+" { return "Plus"; }
    / "-" { return "Minus"; }
    / "@" { return "Atsign"; }
    / "&" { return "Ampersand"; }
    / "*" { return "Asterisk"; }
    / "!" { return "Exclamation"; }
    / "~" { return "Tilde"; }
    / CharacterMultibyteSymbol { return ["Multibyte", createCodeFromLiteral("Identifier", text())]; }
    / "`" _ main:Formula _ "`" { return ["Word", main]; }
    ) _)* tail:Right { return left(head, tail); }

Right
  = head:Variable tail:(_ (
      "(" _ main:Formula _ ")" { return ["rightbracketsRound", [main]]; }
    / "[" _ main:Formula _ "]" { return ["rightbracketsSquare", [main]]; }
    / "{" _ main:Formula _ "}" { return ["rightbracketsCurly", [main]]; }
    / "(" _ ")" { return ["rightbracketsRound", [createCodeFromLiteral("Void", "void")]]; }
    / "[" _ "]" { return ["rightbracketsSquare", [createCodeFromLiteral("Void", "void")]]; }
    / "{" _ "}" { return ["rightbracketsCurly", [createCodeFromLiteral("Void", "void")]]; }
    / "::" _ main:Variable { return ["operatorColon2", [main]]; }
    / "." _ main:Variable { return ["operatorPeriod", [main]]; }
    / "#" _ main:Variable { return ["operatorHash", [main]]; }
    / "++" { return ["rightPlus2", []]; }
    / "--" (! ">") { return ["rightMinus2", []]; }
    / "..." { return ["rightPeriod3", []]; }
    ))* { return right(head, tail); }

Variable
  = head:((
      "$" { return "Dollar"; }
    ) _)* tail:Factor { return left(head, tail); }

Factor
  = "(" _ main:Formula _ ")" { return createCodeFromMethod("bracketsRound", [main]); }
  / "[" _ main:Formula _ "]" { return createCodeFromMethod("bracketsSquare", [main]); }
  / "{" _ main:Formula _ "}" { return createCodeFromMethod("bracketsCurly", [main]); }
  / "(" _ ")" { return createCodeFromMethod("bracketsRound", [createCodeFromLiteral("Void", "void")]); }
  / "[" _ "]" { return createCodeFromMethod("bracketsSquare", [createCodeFromLiteral("Void", "void")]); }
  / "{" _ "}" { return createCodeFromMethod("bracketsCurly", [createCodeFromLiteral("Void", "void")]); }
  / Composite
  / Identifier
  / String
  / StringReplaceable
  / HereDocument
  / Statement

Statement
  = "/" head:Identifier main:(_ ContentStatement)* (_ "/" (! Identifier))? {
      var array = [head];
      main.map(function(item) { array.push(item[1]); })
      return createCodeFromMethod("statement", array);
    }

ContentStatement
  = head:FactorStatement tail:(_ (",") _ FactorStatement)* { return enumerate(head, tail, "Comma"); }
  / Statement

FactorStatement
  = head:Variable tail:(_ (
      "::" _ main:Variable { return ["operatorColon2", [main]]; }
    / "." _ main:Variable { return ["operatorPeriod", [main]]; }
    / "#" _ main:Variable { return ["operatorHash", [main]]; }
    ))* { return right(head, tail); }

Composite
  = head:Number body:BodyComposite tail:Composite { return createCodeFromMethod("operatorComposite", [head, body, tail]); }
  / head:Number body:BodyComposite { return createCodeFromMethod("rightComposite", [head, body]); }
  / head:Number { return head; }

Number
  = Float
  / Hex
  / Integer

Float "Float"
  = [0-9]+ ("." [0-9]+)? [eE] [+-]? [0-9]+ { return createCodeFromLiteral("Float", parseFloat(text())); }
  / [0-9]+ "." [0-9]+ { return createCodeFromLiteral("Float", parseFloat(text())); }

Integer "Integer"
  = [0-9]+ { return createCodeFromLiteral("Integer", parseInt(text(), 10)); }

Hex "Hex"
  = "0x" main:([0-9a-zA-Z]+ { return text(); }) { return createCodeFromLiteral("Integer", parseInt(main, 16)); }

BodyComposite
  = CharacterIdentifier+ { return createCodeFromLiteral("Affix", text()); }

Identifier "Identifier"
  = CharacterIdentifier ([0-9] / CharacterIdentifier)* { return createCodeFromLiteral("Identifier", text()); }

String
  = "'" main:ContentString* "'" { return createCodeFromLiteral("String", main.join("")); }

ContentString
  = "\\\\" { return "\\"; }
  / "\\\"" { return "\""; }
  / "\\'" { return "'"; }
  / "\\$" { return "$"; }
  / "\\r" { return "\r"; }
  / "\\n" { return "\n"; }
  / "\\t" { return "\t"; }
  / "\\x" main:([a-zA-Z0-9][a-zA-Z0-9] { return text(); }) { return String.fromCharCode(parseInt(main, 16)); }
  / "\\u" main:([a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9] { return text(); }) { return String.fromCharCode(parseInt(main, 16)); }
  / [^'\\]

StringReplaceable
  = "\"" main:ContentStringReplaceable "\"" { return main; }

ContentStringReplaceable
  = head:ContentStringReplaceableText tail:(ContentStringReplaceableReplacement ContentStringReplaceableText)* {
      var codes = [head];
      var i;
      for (i = 0; i < tail.length; i++) {
        codes.push(tail[i][0]);
        codes.push(tail[i][1]);
      }
      return createCodeFromMethod("concatenateLiteral", codes);
    }

ContentStringReplaceableText
  = main:(
      "\\\\" { return "\\"; }
    / "\\\"" { return "\""; }
    / "\\'" { return "'"; }
    / "\\$" { return "$"; }
    / "\\r" { return "\r"; }
    / "\\n" { return "\n"; }
    / "\\t" { return "\t"; }
    / "\\x" main:([a-zA-Z0-9][a-zA-Z0-9] { return text(); }) { return String.fromCharCode(parseInt(main, 16)); }
    / "\\u" main:([a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9] { return text(); }) { return String.fromCharCode(parseInt(main, 16)); }
    / [^"$\\]
    )* { return createCodeFromLiteral("String", main.join("")); }

ContentStringReplaceableReplacement
  = "$" "(" main:Formula ")" { return main; }
  / "$" "{" main:Formula "}" { return createCodeFromMethod("leftDollar", [main]); }
  / "$" main:(Integer / Identifier) { return createCodeFromMethod("leftDollar", [main]); }

HereDocument
  = "%" head:(
      head:Identifier "(" _ tail:Formula _ ")" { return [head, tail]; }
    / head:Identifier "(" _ ")" { return [head, createCodeFromLiteral("Void", "void")]; }
    )? tail:(
      ";" { return createCodeFromLiteral("Void", "void"); }
    / (
        begin:HereDocumentDelimiter main:(
          "{" main:(

            main:(! ("}" end:HereDocumentDelimiter & { return begin === end; }) main:(
              "%%" { return "%"; }
            / [^%]
            ) { return main; })+ { return createCodeFromLiteral("String", main.join("")); }
          / HereDocument

          )* "}" { return createCodeFromMethod("concatenateHereDocument", main); }
        / "[" main:(

            main:(! ("]" end:HereDocumentDelimiter & { return begin === end; }) main:(
              .
            ) { return main; })+ { return createCodeFromLiteral("String", main.join("")); }

          )* "]" { return createCodeFromMethod("concatenateHereDocument", main); }
        / begin2:HereDocumentDelimiter2 main:(

            main:(! (end2:HereDocumentDelimiter2 end:HereDocumentDelimiter & { return begin2 === end2 && begin === end; }) main:(
              .
            ) { return main; })+ { return createCodeFromLiteral("String", main.join("")); }

          )* HereDocumentDelimiter2 { return createCodeFromMethod("concatenateHereDocument", main); }
        ) HereDocumentDelimiter { return main; }
      / (
          "{" main:(

            main:(! ("}") main:(
              "%%" { return "%"; }
            / [^%]
            ) { return main; })+ { return createCodeFromLiteral("String", main.join("")); }
          / HereDocument

          )* "}" { return createCodeFromMethod("concatenateHereDocument", main); }
        / "[" main:(

            main:(! ("]") main:(
              .
            ) { return main; })+ { return createCodeFromLiteral("String", main.join("")); }

          )* "]" { return createCodeFromMethod("concatenateHereDocument", main); }
        / begin2:HereDocumentDelimiter2 main:(

            main:(! (end2:HereDocumentDelimiter2 & { return begin2 === end2; }) main:(
              .
            ) { return main; })+ { return createCodeFromLiteral("String", main.join("")); }

          )* HereDocumentDelimiter2 { return createCodeFromMethod("concatenateHereDocument", main); }
        )
      )
    ) {
      if (head !== null) {
        return createCodeFromMethod("hereDocumentFunction", [head[0], head[1], tail]);
      } else {
        return tail;
      }
    }
  / "%" head:(
      "(" _ tail:Formula _ ")" { return tail; }
    / "(" _ ")" { return createCodeFromLiteral("Void", "void"); }
    ) {
      return head;
    }

HereDocumentDelimiter
  = CharacterIdentifier+ { return text(); }

HereDocumentDelimiter2
  = [!"#$%&'*+,\-./:=?@\\^_`|~] { return text(); }

_ "Comments"
  = (
      "/*" ((! "*/") .)* "*/"
    / CommentBlockNested
    / "//" [^\n\r]*
    / "#!" [^\n\r]*
    / CharacterBlank+
    )*

CommentBlockNested
  = "/+" (
      (! ("/+" / "+/")) .
    / CommentBlockNested
    )* "+/"

CharacterMultibyteSymbol
  = CharacterSurrogates
  / (! (CharacterSymbol / CharacterNumber / CharacterIdentifier / CharacterBlank / CharacterContectSurrogates)) .

CharacterSymbol
  = (! (CharacterNumber / CharacterAlphabet / CharacterSymbolIdentifier)) [!-~]

CharacterIdentifier
  = CharacterAlphabet
  / CharacterSymbolIdentifier
  / CharacterHiragana
  / CharacterKatakana
  / CharacterCJKUnifiedIdeographsExtensionA
  / CharacterCJKUnifiedIdeographs

CharacterNumber
  = [0-9]

CharacterAlphabet
  = [a-zA-Z]

CharacterSymbolIdentifier
  = [_]

CharacterHiragana
  = [\u3040-\u309F]

CharacterKatakana
  = [\u30A0-\u30FF]

CharacterCJKUnifiedIdeographsExtensionA
  = [\u3400-\u4DBF]

CharacterCJKUnifiedIdeographs
  = [\u4E00-\u9FFF]

CharacterSurrogates
  = CharacterContectSurrogates CharacterContectSurrogates { return text(); }

CharacterContectSurrogates
  = [\uD800-\uDBFF\uDC00-\uDFFF]

CharacterBlank
  = [ \t\n\r　]
