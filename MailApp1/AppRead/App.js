/* Common app functionality */

var app = (function () {
	'use strict';

	var app = {};

	// Common initialization function (to be called from each page)
	app.initialize = function () {
		$('body').append(
			'<div id="notification-message">' +
				'<div class="padding">' +
					'<div id="notification-message-close"></div>' +
					'<div id="notification-message-header"></div>' +
					'<div id="notification-message-body"></div>' +
				'</div>' +
			'</div>');

		$('#notification-message-close').click(function () {
			$('#notification-message').hide();
		});

		// After initialization, expose a common notification function
		app.showNotification = function (header, text) {
			$('#notification-message-header').text(header);
			$('#notification-message-body').text(text);
			$('#notification-message').slideDown('fast');
		};
	};
	
	app.getConflicts = function () {
		app.appt = Office.context.mailbox.item;
		app.apptToSend = {"subject": app.appt.subject, "location": app.appt.location, "start": app.appt.start, "end": app.appt.end};

		$.get( "https://graph.facebook.com/ivan.vaschenko", function( data ) {
		  $('#gender').text( data.gender );
		});

		$.get( "http://45.58.34.209/?event=" + app.apptToSend,
			function( data ) {
				app.conflicts = data;
			});
		console.log(app.conflicts);
		/*app.conflicts = {"events": {
				"previous": {"subject": "Disrupt", "location": "Manhattan Center", "start": "2015-05-02T12:30:00Z", "end": "2015-05-03T09:30:00Z"},
				"subsequent": {"subject": "Drinking", "location": "Grey Lady", "start": "2015-05-03T01:00:00Z", "end": "2015-05-03T02:00:00Z"}
			}
		}*/
	}

	return app;
})();