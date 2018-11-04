ws = function ws() {
	const socket = new SockJS("/stomp")
	const stompClient = webstomp.over(socket, { debug: false })
	//chan and callback to subscribe when connected, used when user called sub() before connected
	let toSub = []

	//callback to call when connected
	let onCtxCb = []

	stompClient.connect({}, function() {
		onCtxCb.forEach(cb => cb())
		onCtxCb = []

		toSub.forEach(v => {
			stompClient.subscribe(v.chan, v.callback)
		})
		toSub = []
	});

	return {
		onConnect(callback) {
			if (stompClient.connected) {
				callback()
			} else {
				onCtxCb.push(callback)
			}
			return this
		},

		sub(chan, callback) {
			if (stompClient.connected) {
				stompClient.subscribe(chan. callback)
			} else {
				toSub.push({ chan: chan, callback: callback })
			}
			return this
		}
	}
}()