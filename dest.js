
function dicebot_script_openclose(element)
{
	var $script = $(element);

	while (!$script.is(".dicebot_container")) {
		$script = $script.parent();
	}

	$script = $script.find(".dicebot_script_container");
	if ($script.css("display") === "none") {
		$script.css("display", "inline");
	} else {
		$script.css("display", "none");
	}
}

function dicebot_report_openclose(element)
{
	var $script = $(element);

	while (!$script.is(".dicebot_container")) {
		$script = $script.parent();
	}

	$script = $script.find(".dicebot_report");
	if ($script.css("display") === "none") {
		$script.css("display", "inline");
	} else {
		$script.css("display", "none");
	}
}

