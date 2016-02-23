
// http://iwb.jp/jquery-javascript-html-escape/
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
		'>': '&gt;',
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

// http://plusblog.jp/4654/ modified
(function($) {
    var caretPos = function(pos) {
        var item = this.get(0);
        if (pos == null) {
            return get(item);
        } else {
            set(item, pos);
            return this;
        }
    };

    var get = function(item) {
        var CaretPos = 0, start;
        if (item.selectionStart || item.selectionStart == "0") { // Firefox, Chrome
            start = item.selectionStart;
        } else if (document.selection) { // IE
             start = getSelectionCount(item)[0];
        }
        
        if (isNaN (start)){
            return;
        }
        
        return start;
    };
    var set = function(item, pos) {
        if (item.setSelectionRange) {  // Firefox, Chrome
            item.setSelectionRange(pos, pos);
        } else if (item.createTextRange) { // IE
            var range = item.createTextRange();
            range.collapse(true);
            range.moveEnd("character", pos);
            range.moveStart("character", pos);
            range.select();
        }
    };
    
    $.fn.extend({caretPos: caretPos});
})(jQuery);

