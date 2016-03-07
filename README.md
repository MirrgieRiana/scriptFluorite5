# Fluorite 5.5.0

## Usage

```javascript
// import PEGJS
var fluorite5_pegjs = ~~~~~~~; // the content of fluorite5.pegjs
var script = ~~~~~~; // fluorite5 script code

var parser = PEG.buildParser(fluorite5_pegjs, {
  cache: true,
  allowedStartRules: [
    "ExpressionPlain",
  ],
});

var res = parser.parse(script, {
  startRule: "ExpressionPlain",
});
```
