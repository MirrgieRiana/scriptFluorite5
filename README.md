# Fluorite 5.6.0

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

## Command Line

*Windows only*

`fluorite5 -h`

`fluorite5 -e "20 * 5"`

`fluorite5 sample.flu5 -g`

`echo 5*20 | fluorite5`
