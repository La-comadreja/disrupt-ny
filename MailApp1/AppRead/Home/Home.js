/// <reference path="../App.js" />
/*global app*/

(function () {
	'use strict';

	// The Office initialize function must be run each time a new page is loaded
	Office.initialize = function (reason) {
		$(document).ready(function () {
			app.initialize();
			app.getConflicts();
			displayItemDetails();
		});
	};

	// Displays the "Subject" and "From" fields, based on the current mail item
	function displayItemDetails() {
	
		$('#start').text( app.appt.start );
		$('#end').text( app.appt.end );
		
		var s = "", prev = app.conflicts.events.previous, next = app.conflicts.events.subsequent;
		if (prev) s += prev.subject + " at " + prev.location + "<br/>";
		if (next) s += next.subject + " at " + next.location + "<br/>";
		
		$('#conflicts').html( s );
	}
})();