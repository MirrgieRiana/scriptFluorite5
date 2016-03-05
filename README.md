# Fluorite 5.5.0

## Usage

```javascript
// import PEGJS
var fluorite5_pegjs = ~~~~~~~; // the content of fluorite5.pegjs
var script = ~~~~~~; // fluorite5 script code
var vm_name = "standard" // "standard" or "classic"

var parser = PEG.buildParser(fluorite5_pegjs, {
  cache: true,
  allowedStartRules: [
    "Expression",
    "VMFactory",
  ],
});

var res = parser.parse(script, {
  startRule: "Expression",
});

var VM = parser.parse(vm_name, {
  startRule: "VMFactory",
});
var vm = new VM();

vm.toNative(

var text = [res[0]];
for (var i = 1; i < res.length; i += 2) {
  try {
    text.push(vm.toNative(res[i](vm, "get")));
  } catch (e) {
    text.push("[Error: " + e + "]");
  }
  text.push(res[i + 1]);
}

text.join("");
```
