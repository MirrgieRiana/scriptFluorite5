/*
 * Fluorite 5.5.0
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

_ "Blanks"
  = [ \t\n\r　]*

