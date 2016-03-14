var argv = require("argv");
var PEG = require("pegjs");
var fs = require('fs');
var readline = require('readline');

main();

function main()
{
	argv.version('0.0.1');
	argv.option({
		name: 'evaluate',
		short: 'e',
		type : 'string',
		description :'Evaluate one line program',
		example: "'-e \"\\\\40 + 60\\\\\"'"
	});
	argv.option({
		name: 'message',
		short: 'm',
		type : 'boolean',
		description :'If true, parse as message',
		example: "'-m'"
	});
	argv.option({
		name: 'charcode',
		short: 'c',
		type : 'string',
		description :'charcode of source code',
		example: "'-c \"utf8\"'"
	});
	argv.option({
		name: 'runtime',
		short: 'r',
		type : 'string',
		description :'PEGJS file of Fluorite5',
		example: "'-runtime \"lib/fluorite5.pegjs\"'"
	});

	run(argv.run());
}

function run(args)
{
	var charcode = args.options.charcode || 'utf8';
	var runtime = args.options.runtime || 'fluorite5.pegjs';

	// ready parser
	fs.readFile(runtime, charcode, function (err, text) {
		if (err) {
			console.error("Error: Fluorite5 runtime file is illegal");
			console.error(err);
			process.exit(7);
		} else {
			var parser;
			try {
				parser = PEG.buildParser("" + text, {
					cache: true,
					allowedStartRules: [
						"ExpressionPlain",
					],
				});
			} catch (e) {
				console.error("Error: Parse error at Fluorite5 runtime file");
				console.error(e);
				process.exit(8);
			}
			parseAll(args, parser);
		}
	});

}

function parseAll(args, parser)
{
	var charcode = args.options.charcode || 'utf8';

	var processed = 0;

	// -e "~~~"
	if (args.options.evaluate !== undefined) {

		processSourceCode(args, parser, args.options.evaluate);
		processed++;

	}

	// File...
	for (var i = 0; i < args.targets.length; i++) {
		var file = args.targets[i];
		if (file !== "") {

			fs.readFile(file, charcode, function (err, text) {
				if (err) {
					console.error("Error: Fluorite5 file is illegal");
					console.error(err);
				} else {
					processSourceCode(args, parser, "" + text);
				}
			});
			processed++;

		}
	}

	// stdin
	if (processed == 0) {
		var lines = [];
		var reader = readline.createInterface({
			input: process.stdin,
			output: process.stdout
		});
		reader.on('line', function (line) {
			lines.push(line);
		});
		process.stdin.on('end', function () {
			processSourceCode(args, parser, lines.join("\n"));
		});
	}

}

function processSourceCode(args, parser, source)
{
	var message = args.options.message;

	console.log(parser.parse(message ? source : "\\" + source + "\\", {
		startRule: "ExpressionPlain",
	}));
}

