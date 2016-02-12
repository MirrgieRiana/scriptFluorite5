/*
 * Fluorite 5.1.0
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
  = head:Factor tail:(_ ("+" / "-") _ Factor)* {
      var result = head, i;

      for (i = 0; i < tail.length; i++) {
        if (tail[i][1] === "+") { result += tail[i][3]; }
        if (tail[i][1] === "-") { result -= tail[i][3]; }
      }

      return result;
    }

Factor
  = "(" _ main:Formula _ ")" { return main; }
  / Dice
  / Float
  / Integer

Dice
  = count:Integer "d" faces:Integer { return dice(count, faces); }
  / count:Integer "d" { return dice(count, 6); }

Float "Float"
  = [0-9]+ ("." [0-9]+)? [eE] [+-]? [0-9]+ { return parseFloat(text()); }
  / [0-9]+ "." [0-9]+ { return parseFloat(text()); }

Integer "Integer"
  = [0-9]+ { return parseInt(text(), 10); }

_ "Blanks"
  = [ \t\n\r]*
