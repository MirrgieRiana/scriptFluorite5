/*
 * Fluorite 5.2.0
 * ==============
 */

{
  var dices = [];
  
  function dice(count, faces)
  {
    var t = 0, i, value, values = [];
    for (i = 0; i < count; i++) {
      value = Math.floor(Math.random() * faces) + 1;
      t += value;
      values.push(value);
    }
    dices.push(values);
    return t;
  }
}

Expression
  = Message

Message
  = head:Text tail:("\\" _ Formula _ "\\" Text)* {
      var result = [head], i;

      for (i = 0; i < tail.length; i++) {
        result.push(tail[i][2]);
        result.push(tail[i][5]);
      }

      return [result, dices];
    }

Text
  = [^\\]* { return text(); }

Formula
  = Or

Or
  = head:And tail:(_ ("||") _ And)* {
      var result = head, i;

      for (i = 0; i < tail.length; i++) {
        if (tail[i][1] === "||") { result = result || tail[i][3]; }
      }

      return result;
    }

And
  = head:Compare tail:(_ ("&&") _ Compare)* {
      var result = head, i;

      for (i = 0; i < tail.length; i++) {
        if (tail[i][1] === "&&") { result = result && tail[i][3]; }
      }

      return result;
    }

Compare
  = head:Add tail:(_ (">=" / ">" / "<=" / "<" / "!=" / "==") _ Add)* {
      var left = head, i;
      if (tail.length == 0) return head;

      for (i = 0; i < tail.length; i++) {
        if (tail[i][1] === ">") if (!(left > tail[i][3])) return false;
        if (tail[i][1] === ">=") if (!(left >= tail[i][3])) return false;
        if (tail[i][1] === "<") if (!(left < tail[i][3])) return false;
        if (tail[i][1] === "<=") if (!(left <= tail[i][3])) return false;
        if (tail[i][1] === "==") if (!(left == tail[i][3])) return false;
        if (tail[i][1] === "!=") if (!(left != tail[i][3])) return false;

        left = tail[i][3];
      }

      return true;
    }

Add
  = head:Term tail:(_ ("+" / "-") _ Term)* {
      var result = head, i;

      for (i = 0; i < tail.length; i++) {
        if (tail[i][1] === "+") { result += tail[i][3]; }
        if (tail[i][1] === "-") { result -= tail[i][3]; }
      }

      return result;
    }

Term
  = head:Power tail:(_ ("*" / "/") _ Power)* {
      var result = head, i;

      for (i = 0; i < tail.length; i++) {
        if (tail[i][1] === "*") { result *= tail[i][3]; }
        if (tail[i][1] === "/") { result /= tail[i][3]; }
      }

      return result;
    }

Power
  = head:(Signed _ ("^") _)* tail:Signed {
      var result = tail, i;

      for (i = head.length - 1; i >= 0; i--) {
        if (head[i][2] === "^") { result = Math.pow(head[i][0], result); }
      }

      return result;
    }

Signed
  = head:(("+" / "-") _)* tail:Factor {
      var result = tail, i;
      
      for (i = head.length - 1; i >= 0; i--) {
        if (head[i][0] === "+") { }
        if (head[i][0] === "-") { result = -result; }
      }
      
      return result;
    }

Factor
  = "(" _ main:Formula _ ")" { return main; }
  / Dice
  / Float
  / Integer
  / Identifier

Dice
  = count:Integer "d" faces:Integer { return dice(count, faces); }
  / count:Integer "d" { return dice(count, 6); }

Float "Float"
  = [0-9]+ ("." [0-9]+)? [eE] [+-]? [0-9]+ { return parseFloat(text()); }
  / [0-9]+ "." [0-9]+ { return parseFloat(text()); }

Integer "Integer"
  = [0-9]+ { return parseInt(text(), 10); }

Identifier "Identifier"
  = [a-zA-Z]+ { return text(); }

_ "Blanks"
  = [ \t\n\r]*
