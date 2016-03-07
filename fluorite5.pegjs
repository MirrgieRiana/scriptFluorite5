/*
 * Fluorite 5.6.0
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
      return vm.callMethod(operator, codes, context, args);
    };
  }

  function operatorLeft(head, tail)
  {
    var result = head, i;
    for (i = 0; i < tail.length; i++) {
      result = createCodeFromMethod("_operator" + tail[i][1], [result, tail[i][3]]);
    }
    return result;
  }

  function operatorRight(head, tail)
  {
    var result = tail, i;
    for (i = head.length - 1; i >= 0; i--) {
      result = createCodeFromMethod("_operator" + head[i][2], [head[i][0], result]);
    }
    return result;
  }

  function left(head, tail)
  {
    var result = tail, i;
    for (i = head.length - 1; i >= 0; i--) {
      result = createCodeFromMethod("_left" + head[i][0], [result]);
    }
    return result;
  }

  function right(head, tail)
  {
    var result = head, i;
    for (i = 0; i < tail.length; i++) {
      result = createCodeFromMethod("_rightbrackets" + tail[i][1][0], [result, tail[i][1][1]]);
    }
    return result;
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
        this.toString = function(value) {
          return "" + value;
        };
        this.toNative = function(value) {
          return value;
        };
        this.allTrue = function(array) {
          for (var i = 0; i < array.length; i++) {
            if (!array[i]) return false;
          }
          return true;
        };
        this.createLiteral = function(type, value, context, args) {
          return value;
        };
      };
    } else if (name === "standard") {
      return function() {
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
        function createFunction(args, code)
        {
          return createObject(typeFunction, {
            args: args,
            code: code,
          });
        }
        function callFunction(blessedFunction, blessedArgs)
        {
          var i;
          var array = unpackVector(blessedArgs);
          for (i = 0; i < blessedFunction.value.args.length; i++) {
            variables[blessedFunction.value.args[i]] = array[i] || UNDEFINED;
          }
          variables["_"] = packVector(array.slice(i, array.length));
          return blessedFunction.value.code(vm, "get");
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
        var typeHash = createObject(typeType, "Hash");

        var UNDEFINED = createObject(typeUndefined, undefined);

        var variables = {
          pi: createObject(typeNumber, Math.PI),
          sin: createFunction(["x"], function(vm, context) {
              return createObject(typeNumber, Math.sin(getVariable("x").value));
          }),
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
              var minus = operator == "_operatorMinus2Greater";
              if (minus) {
                return packVector(unpackVector(codes[0](vm, "get")).map(function(scalar) {
                  return callFunction(createFunction([], codes[1]), scalar);
                }));
              } else {
                return callFunction(createFunction([], codes[1]), codes[0](vm, "get"));
              }
            }
            if (operator === "_operatorMinusGreater"
              || operator === "_operatorEqualGreater") 	{
              var minus = operator == "_operatorMinusGreater";
              var right = codes[1](vm, "get");
              if (instanceOf(right, typeKeyword)) right = getVariable(right.value);
              if (instanceOf(right, typeFunction)) {
                if (minus) {
                  return packVector(unpackVector(codes[0](vm, "get")).map(function(scalar) {
                    return callFunction(right, scalar);
                  }));
                } else {
                  return callFunction(right, codes[0](vm, "get"));
                }
              }
              throw "Type Error: " + operator + "/" + right.type.value;
            }
            if (operator === "_operatorColon") return createObject(typeEntry, {
              key: codes[0](vm, "get"),
              value: codes[1](vm, "get"),
            });
            if (operator === "d") return createObject(typeNumber, dice(codes[0](vm, "get").value, codes[1](vm, "get").value));
            if (operator === "_leftDollar") return getVariable(codes[0](vm, "get").value);
            if (operator === "_rightbracketsRound") {
              var value = codes[0](vm, "get");
              if (instanceOf(value, typeKeyword)) value = getVariable(value.value);
              if (instanceOf(value, typeFunction)) return callFunction(value, codes[1](vm, "get"));
              throw "Type Error: " + operator + "/" + value.type.value;
            }
            if (operator === "_statement") {
              var command = codes[0](vm, "get");
              if (command.value === "typeof") {
                var value = codes[1](vm, "get");
                return value.type;
              }
              if (command.value === "length") {
                var value = codes[1](vm, "get");
                if (instanceOf(value, typeArray)) return createObject(typeNumber, value.value.length);
                if (instanceOf(value, typeVector)) return createObject(typeNumber, value.value.length);
                if (instanceOf(value, typeString)) return createObject(typeNumber, value.value.length);
                throw "Illegal Argument: " + value.type.value;
              }
              if (command.value === "size") {
                var value = codes[1](vm, "get");
                return createObject(typeNumber, unpackVector(value).length);
              }
              throw "Unknown command: " + command.value;
            }
            if (operator === "_leftAmpersand") return createObject(typePointer, codes[0]);
            if (operator === "_bracketsCurly") {
              var hash = {};
              unpackVector(codes[0](vm, "get")).forEach(function(item) {
                if (instanceOf(item, typeEntry)) {
                  hash[item.value.key.value] = item.value.value;
                  return;
                }
                throw "Type Error: " + item.type.value + " is not a Entry";
              });
              return createObject(typeHash, hash);
            }
            if (operator === "_operatorColon2") {
              var hash = codes[0](vm, "get");
              var key = codes[1](vm, "get");
              if (instanceOf(hash, typeHash)) {
                if (instanceOf(key, typeString)) return hash.value[key.value] || UNDEFINED;
                if (instanceOf(key, typeKeyword)) return hash.value[key.value] || UNDEFINED;
              }
              throw "Type Error: " + hash.type.value + "[" + key.type.value + "]";
            }
            if (operator === "_operatorColonGreater") {
              var array = unpackVector(codes[0](vm, "arguments")).map(function(item) { return item.value; });
              return createFunction(array, codes[1]);
            }

            throw "Unknown operator: " + operator;
          } else if (context === "arguments") {
            if (operator === "_bracketsRound") return codes[0](vm, "arguments");
            if (operator === "_leftDollar") return codes[0](vm, "arguments");
            if (operator === "_enumerateComma") return packVector(codes.map(function(code) { return code(vm, "arguments"); }));
            throw "Unknown operator: " + operator;
          } else {
            throw "Unknown context: " + context;
          }
        };
        this.toString = function(value) {
          var vm = this;
          if (instanceOf(value, typeUndefined)) {
            return "<Undefined>";
          }
          if (instanceOf(value, typeVector)) {
            if (value.value.length == 0) return "<Void>";
            return value.value.map(function(scalar) { return vm.toString(scalar); }).join(", ");
          }
          if (instanceOf(value, typeArray)) {
            return "[" + value.value.map(function(scalar) { return vm.toString(scalar); }).join(", ") + "]";
          }
          if (instanceOf(value, typeEntry)) {
            return vm.toString(value.value.key) + ": " + vm.toString(value.value.value);
          }
          if (instanceOf(value, typeHash)) {
            return "{" + Object.keys(value.value).map(function(key) {
              return key + ": " + vm.toString(value.value[key]);
            }).join(", ") + "}";
          }
          if (instanceOf(value, typeFunction)) {
            if (value.value.args.length === 0) return "<Function>";
            return "<Function: " + value.value.args.join(", ") + ">";
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
        this.createLiteral = function(type, value, context, args) {
          if (context === "get") {
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
            if (type === "Void") return packVector([]);
          } else if (context === "arguments") {
            if (type === "Identifier") return createObject(typeKeyword, value);
            if (type === "Void") return packVector([]);
          }
          throw "Unknown Literal Type: " + context + "/" + type;
        };
      };
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
          texts.push(vm.toString(main[i][1](vm, "get")));
        } catch (e) {
          texts.push("[Error: " + e + "][" + main[i][0] + "]");
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
  = head:MessageText tail:("\\" _ MessageFormula _ "\\" MessageText)* {
      var result = [head], i;

      for (i = 0; i < tail.length; i++) {
        result.push(tail[i][2]);
        result.push(tail[i][5]);
      }

      return result;
    }

MessageText
  = [^\\]* { return text(); }

MessageFormula
  = main:Formula {
      return [text(), main];
    }

Formula
  = Arrows

Arrows
  = head:(
      (
        main:Vector _ "-->" _ { return ["Minus2Greater", main]; }
      / main:Vector _ "->" _ (! ":") { return ["MinusGreater", main]; }
      / main:Vector _ "==>" _ { return ["Equal2Greater", main]; }
      / main:Vector _ "=>" _ { return ["EqualGreater", main]; }
      )+
    / main:Vector _ ":>" _ { return [["ColonGreater", main]]; }
    )* tail:Vector {
      var result = tail, i, j;
      for (i = head.length - 1; i >= 0; i--) {
        var result2 = head[i][0][1];
        for (j = 1; j < head[i].length; j++) {
          result2 = createCodeFromMethod("_operator" + head[i][j - 1][0], [result2, head[i][j][1]]);
        }
        result = createCodeFromMethod("_operator" + head[i][head[i].length - 1][0], [result2, result]);
      }
      return result;
    }

Vector
  = head:Entry tail:(_ (",") _ Entry)* {
      if (tail.length == 0) return head;
      var result = [head], i;

      for (i = 0; i < tail.length; i++) {
        result.push(tail[i][3]);
      }

      return createCodeFromMethod("_enumerateComma", result);
    }

Entry
  = head:Range tail:(_ (
      ":" { return "Colon"; }
    ) _ Range)* { return operatorLeft(head, tail); }

Range
  = head:Or tail:(_ (
      "~" { return "Tilde"; }
    / ".." { return "Period2"; }
    ) _ Or)* { return operatorLeft(head, tail); }

Or
  = head:And tail:(_ (
      "||" { return "Pipe2"; }
    ) _ And)* { return operatorLeft(head, tail); }

And
  = head:Compare tail:(_ (
      "&&" { return "Ampersand2"; }
    ) _ Compare)* { return operatorLeft(head, tail); }

Compare
  = head:Add tail:(_ (
      ">=" { return "GreaterEqual"; }
    / ">" { return "Greater"; }
    / "<=" { return "LessEqual"; }
    / "<" { return "Less"; }
    / "!=" { return "ExclamationEqual"; }
    / "==" { return "Equal2"; }
    ) _ Add)* {
      if (tail.length == 0) return head;
      var codes = [], left = head, right, i;

      for (i = 0; i < tail.length; i++) {
        right = tail[i][3];
        codes.push(createCodeFromMethod("_operator" + tail[i][1], [left, right]));
        left = right;
      }

      return function(vm, context, args) {
        if (context === "get") {
          return vm.allTrue(codes.map(function(code) { return code(vm, "get"); }));
        } else {
          throw "Unknown context: " + context;
        }
      };
    }

Add
  = head:Term tail:(_ (
      "+" { return "Plus"; }
    / "-" { return "Minus"; }
    ) _ Term)* { return operatorLeft(head, tail); }

Term
  = head:Power tail:(_ (
      "*" { return "Asterisk"; }
    / "/" { return "Slash"; }
    ) _ Power)* { return operatorLeft(head, tail); }

Power
  = head:(Statement _ (
      "^" { return "Caret"; }
    ) _)* tail:Statement { return operatorRight(head, tail); }

Statement
  = Left
  / "/" main:(_ Member)+ {
      return createCodeFromMethod("_statement", main.map(function(item) { return item[1]; }));
    }

Left
  = head:((
      "+" { return "Plus"; }
    / "-" { return "Minus"; }
    / "@" { return "Atsign"; }
    / "&" { return "Ampersand"; }
    / "*" { return "Asterisk"; }
    ) _)* tail:Right { return left(head, tail); }

Right
  = head:Member tail:(_ (
      "(" _ main:Formula _ ")" { return ["Round", main]; }
    / "[" _ main:Formula _ "]" { return ["Square", main]; }
    / "{" _ main:Formula _ "}" { return ["Curly", main]; }
    / "(" _ ")" { return ["Round", createCodeFromLiteral("Void", "void")]; }
    / "[" _ "]" { return ["Square", createCodeFromLiteral("Void", "void")]; }
    / "{" _ "}" { return ["Curly", createCodeFromLiteral("Void", "void")]; }
    ))* { return right(head, tail); }

Member
  = head:Variable tail:(_ (
      "::" { return "Colon2"; }
    ) _ Variable)* { return operatorLeft(head, tail); }

Variable
  = head:((
      "$" { return "Dollar"; }
    ) _)* tail:Factor { return left(head, tail); }

Factor
  = "(" _ main:Formula _ ")" { return createCodeFromMethod("_bracketsRound", [main]); }
  / "[" _ main:Formula _ "]" { return createCodeFromMethod("_bracketsSquare", [main]); }
  / "{" _ main:Formula _ "}" { return createCodeFromMethod("_bracketsCurly", [main]); }
  / "(" _ ")" { return createCodeFromMethod("_bracketsRound", [createCodeFromLiteral("Void", "void")]); }
  / "[" _ "]" { return createCodeFromMethod("_bracketsSquare", [createCodeFromLiteral("Void", "void")]); }
  / "{" _ "}" { return createCodeFromMethod("_bracketsCurly", [createCodeFromLiteral("Void", "void")]); }
  / Dice
  / Float
  / Integer
  / Identifier
  / Underbar
  / String

Dice
  = count:Integer "d" faces:Integer { return createCodeFromMethod("d", [count, faces]); }
  / count:Integer "d" { return createCodeFromMethod("d", [count, createCodeFromLiteral("Integer", 6)]); }

Float "Float"
  = [0-9]+ ("." [0-9]+)? [eE] [+-]? [0-9]+ { return createCodeFromLiteral("Float", parseFloat(text())); }
  / [0-9]+ "." [0-9]+ { return createCodeFromLiteral("Float", parseFloat(text())); }

Integer "Integer"
  = [0-9]+ { return createCodeFromLiteral("Integer", parseInt(text(), 10)); }

Identifier "Identifier"
  = [a-zA-Z][a-zA-Z_]* { return createCodeFromLiteral("Identifier", text()); }

Underbar
  = "_" { return createCodeFromLiteral("Underbar", text()); }

String
  = "'" main:ContentString* "'" { return createCodeFromLiteral("String", main.join("")); }

ContentString
  = "\\\\" { return "\\"; }
  / "\\'" { return "'"; }
  / [^']

_ "Comments"
  = (
      "/*" ((! "*/") .)* "*/"
    / "//" [^\n\r]*
    / Blanks
    )*

Blanks
  = [ \t\n\r　]+

