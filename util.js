
function convHtml(string)
{
	string = escapeHtml(string);
	string = string.replace(/\n|\r\n?/g, "<br>");
	return string;
}

var escapeHtml = (function (String) {
	var escapeMap = {
		'&': '&amp;',
		"'": '&#x27;',
		'`': '&#x60;',
		'"': '&quot;',
		'<': '&lt;',
		'>': '&gt;'
	};
	var escapeReg = '[';
	var reg;
	for (var p in escapeMap) {
		if (escapeMap.hasOwnProperty(p)) {
			escapeReg += p;
		}
	}
	escapeReg += ']';
	reg = new RegExp(escapeReg, 'g');
	return function escapeHtml (str) {
		str = (str === null || str === undefined) ? '' : '' + str;
		return str.replace(reg, function (match) {
			return escapeMap[match];
		});
	};
}(String));

