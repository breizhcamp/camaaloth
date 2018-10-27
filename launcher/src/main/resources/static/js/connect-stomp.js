ws = function ws() {
	const socket = new SockJS("/stomp")
	const stompClient = webstomp.over(socket, { debug: false })
	//chan and callback to subscribe when connected, used when user called sub() before connected
	let toSub = []

	stompClient.connect({}, function() {
		toSub.forEach(v => {
			stompClient.subscribe(v.chan, v.callback)
		})
		toSub = []
	});

	return {
		sub(chan, callback) {
			if (stompClient.connected) {
				stompClient.subscribe(chan. callback)
			} else {
				toSub.push({ chan: chan, callback: callback })
			}
		}
	}
}()