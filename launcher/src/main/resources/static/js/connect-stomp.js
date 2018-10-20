var socket = new SockJS("/stomp");
var stompClient = webstomp.over(socket, { debug: false });

stompClient.connect({}, function() {
	stompClient.subscribe("/osc", function (msg) {
		//console.log(msg);
	})
});