var map;
var marker;
var infowindow;
var messagewindow;

function initMap() {
	var california = {lat: 37.4419, lng: -122.1419};
	map = new google.maps.Map(document.getElementById('map'), {
		center: california,
		zoom: 13
	});

	infowindow = new google.maps.InfoWindow({
		content: document.getElementById('form')
	});

	messagewindow = new google.maps.InfoWindow({
		content: document.getElementById('message')
	});

	google.maps.event.addListener(map, 'click', function(event) {
		if(marker) {
			marker.setPosition(event.latLng);
		}
		else {
			marker = new google.maps.Marker({
				position: event.latLng,
				map: map,
				draggable: true
			});
		}

		google.maps.event.addListener(marker, 'click', function() {
			infowindow.open(map, marker);
		});
	});
}

function saveData() {
	var name = escape(document.getElementById('name').value);
	var address = escape(document.getElementById('address').value);
	var type = document.getElementById('type').value;
	var latlng = marker.getPosition();
	var url = 'phpsqlinfo_addrow.php?name=' + name + '&address=' + address +
	'&type=' + type + '&lat=' + latlng.lat() + '&lng=' + latlng.lng();

	infowindow.close();
	messagewindow.open(map, marker);
}

ajax_text('/source/text/googleapikey.txt').done(function(data) {
	$("body").append('<script async defer src="https://maps.googleapis.com/maps/api/js?key=' + data + '&callback=initMap"></script>');
});

	
