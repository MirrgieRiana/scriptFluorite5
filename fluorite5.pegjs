/*
 * Fluorite 5.4.0
 * ==============
 */

{

  function createCodeFromLiteral(type, value)
  {
    return function(vm, context, args) {
      if (context === "get") {
        return vm.createLiteral(type, value);
      } else {
        throw "Unknown context: " + context;
      }
    };
  }

  function createCodeFromMethod(operator, codes)
  {
    return function(vm, context, args) {
      return vm.callMethod(operator, codes, context, args);
    };
  }

  function VMSimple()
  {
    this.dices = [];
    this.variables = {
      pi: Math.PI,
    };
    this.callMethod = function(operator, codes, context, args) {
      var vm = this;
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
        if (operator === "d") return vm.dice(codes[0](vm, "get"), codes[1](vm, "get"));
        if (operator === "_leftDollar") return vm.variables[codes[0](vm, "get")];
        throw "Unknown operator: " + operator;
      } else {
        throw "Unknown context: " + context;
      }
    };
    this.dice = function(count, faces) {
      var t = 0, i, value, values = [];
      for (i = 0; i < count; i++) {
        value = Math.floor(Math.random() * faces) + 1;
        t += value;
        values.push(value);
      }
      this.dices.push(values);
      return t;
    };
    this.createLiteral = function(type, value) {
      return value;
    };
  }

}

ExpressionPlain
  = main:Expression {
      var strings = [main[0]], i;
      var vm, res;
 
      for (i = 1; i < main.length; i += 2) {
        vm = new VMSimple();
        try {
          res = main[i][1](vm, "get");
        } catch (e) {
          res = e;
        }
        strings.push(res);
        strings.push(main[i + 1]);
      }

      return strings.join("");
    }

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
  = Arrow

Arrow
  = head:Vector tail:(_ (
      "-->" { return "Minus2Greater"; }
    ) _ Vector)* {
      if (tail.length == 0) return head;
      var result = head, i;

      for (i = 0; i < tail.length; i++) {
        result = createCodeFromMethod("_operator" + tail[i][1], [result, tail[i][3]]);
      }

      return result;
    }

Vector
  = head:Or tail:(_ (",") _ Or)* {
      if (tail.length == 0) return head;
      var result = [head], i;

      for (i = 0; i < tail.length; i++) {
        result.push(tail[i][3]);
      }

      return createCodeFromMethod("_enumerateComma", result);
    }

Or
  = head:And tail:(_ (
      "||" { return "Pipe2"; }
    ) _ And)* {
      if (tail.length == 0) return head;
      var result = head, i;

      for (i = 0; i < tail.length; i++) {
        result = createCodeFromMethod("_operator" + tail[i][1], [result, tail[i][3]]);
      }

      return result;
    }

And
  = head:Compare tail:(_ (
      "&&" { return "Ampersand2"; }
    ) _ Compare)* {
      if (tail.length == 0) return head;
      var result = head, i;

      for (i = 0; i < tail.length; i++) {
        result = createCodeFromMethod("_operator" + tail[i][1], [result, tail[i][3]]);
      }

      return result;
    }

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
          var i;

          for (i = 0; i < codes.length; i++) {
            if (!codes[i](vm, "get")) return false;
          }

          return true;
        } else {
          throw "Unknown context: " + context;
        }
      };
    }

Add
  = head:Term tail:(_ (
      "+" { return "Plus"; }
    / "-" { return "Minus"; }
    ) _ Term)* {
      if (tail.length == 0) return head;
      var result = head, i;

      for (i = 0; i < tail.length; i++) {
        result = createCodeFromMethod("_operator" + tail[i][1], [result, tail[i][3]]);
      }

      return result;
    }

Term
  = head:Power tail:(_ (
      "*" { return "Asterisk"; }
    / "/" { return "Slash"; }
    ) _ Power)* {
      if (tail.length == 0) return head;
      var result = head, i;

      for (i = 0; i < tail.length; i++) {
        result = createCodeFromMethod("_operator" + tail[i][1], [result, tail[i][3]]);
      }

      return result;
    }

Power
  = head:(Signed _ (
      "^" { return "Caret"; }
    ) _)* tail:Signed {
      if (tail.length == 0) return head;
      var result = tail, i;

      for (i = head.length - 1; i >= 0; i--) {
        result = createCodeFromMethod("_operator" + head[i][2], [head[i][0], result]);
      }

      return result;
    }

Signed
  = head:((
      "+" { return "Plus"; }
    / "-" { return "Minus"; }
    / "$" { return "Dollar"; }
    ) _)* tail:Factor {
      var result = tail, i;
      
      for (i = head.length - 1; i >= 0; i--) {
        result = createCodeFromMethod("_left" + head[i][0], [result]);
      }
      
      return result;
    }

Factor
  = "(" _ main:Formula _ ")" { return createCodeFromMethod("_bracketsRound", [main]); }
  / Dice
  / Float
  / Integer
  / Identifier

Dice
  = count:Integer "d" faces:Integer { return createCodeFromMethod("d", [count, faces]); }
  / count:Integer "d" { return createCodeFromMethod("d", [count, createCodeFromLiteral("Integer", 6)]); }

Float "Float"
  = [0-9]+ ("." [0-9]+)? [eE] [+-]? [0-9]+ { return createCodeFromLiteral("Float", parseFloat(text())); }
  / [0-9]+ "." [0-9]+ { return createCodeFromLiteral("Float", parseFloat(text())); }

Integer "Integer"
  = [0-9]+ { return createCodeFromLiteral("Integer", parseInt(text(), 10)); }

Identifier "Identifier"
  = [a-zA-Z]+ { return createCodeFromLiteral("Identifier", text()); }

_ "Blanks"
  = [ \t\n\r]*
