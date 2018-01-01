
const Aid1 = artifacts.require("Aid1");
const owner = "0x627306090abab3a6e1400e9345bc60c78a8bef57";
const otherAddress = "0x5aeda56215b167893e80b4fe645ba6d5bab767de";
const decimalPlaces = 18;

function forInstance(msg, cb) {
	return it(msg, () => Aid1.deployed().then(cb));
}

function toFixed(a) {
	return a * Math.pow(10, decimalPlaces);
}

function toFloat(a) {
	return a / Math.pow(10, decimalPlaces);
}

function expectToThrow(cb) {
	var flag = false;
	return cb()
	.catch(() => { flag = true; return assert(true); } )
	.then(() => { if(!flag) return assert(false); });
}

contract('at creation', () => {

	forInstance('owner should own 238,000,000 tokens', instance => {
		return instance.balanceOf.call(owner)
		.then(balance => assert.equal(balance.valueOf(), toFixed(238000000)));
	});	

	forInstance('state should be 0 (SETUP)', instance => {
		return instance.state()
		.then(state => assert.equal(state.valueOf(), 0));
	});	
});

contract('State = 0 (SETUP)', () => {

	forInstance('anybody may transfer tokens', instance => {
		return instance.transfer(otherAddress, toFixed(1))
		.then(flag => assert(flag))
		.then(() => instance.balanceOf.call(owner))
		.then(balance => assert.equal(balance.valueOf(), toFixed(238000000 - 1)))
		.then(() => instance.balanceOf.call(otherAddress))
		.then(balance => assert.equal(balance.valueOf(), toFixed(1)));
	});

	forInstance('should not be possible to call approve', instance => {
		return expectToThrow(() => instance.approve(otherAddress, toFixed(1)));
	});

	forInstance('should not be possible to call transferFrom', instance => {
		return expectToThrow(() => instance.approve(otherAddress, toFixed(1)));
	});

	forInstance('should not be possible to call unlock', instance => {
		return expectToThrow(() => instance.unlock());
	});

	forInstance('should not be possible to call cashOut', instance => {
		return expectToThrow(() => instance.cashOut());
	});
});

contract('State = 1 (LOCKED)', () => {

	forInstance('after lock is called, state should be 1 (LOCKED)', instance => {
		return instance.lock()
		.then(() => instance.state())
		.then(state => assert.equal(state.valueOf(), 1 /* LOCKED */));
	});	

	forInstance('anybody may transfer tokens', instance => {
		return instance.transfer(otherAddress, toFixed(1))
		.then(flag => assert(flag))
		.then(() => instance.balanceOf.call(otherAddress))
		.then(balance => assert.equal(balance.valueOf(), toFixed(1)))
		.then(() => instance.transfer(owner, toFixed(1), { from: otherAddress }))
		.then(flag => assert(flag))
		.then(() => instance.balanceOf.call(otherAddress))
		.then(balance => assert.equal(balance.valueOf(), toFixed(0)));		
	});

	forInstance('should not be possible to call cashOut', instance => {
		return expectToThrow(() => instance.cashOut());
	});
});

contract('State = 2 (UNLOCKED)', () => {

	forInstance('should not be possible to call unlock unless interval has expired', instance => {
		return instance.lock()
		.then(() => expectToThrow(() => instance.unlock()));
	});

	forInstance('after unlock is called, state should be 2 (UNLOCKED)', instance => {
		return instance.unlock()
		.then(() => instance.state())
		.then(state => assert.equal(state.valueOf(), 2 /* UNLOCKED */));
	});	

	forInstance('anybody may transfer tokens', instance => {
		return instance.transfer(otherAddress, toFixed(1))
		.then(flag => assert(flag))
		.then(() => instance.balanceOf.call(otherAddress))
		.then(balance => assert.equal(balance.valueOf(), toFixed(1)))
		.then(() => instance.transfer(owner, toFixed(1), { from: otherAddress }))
		.then(flag => assert(flag))
		.then(() => instance.balanceOf.call(otherAddress))
		.then(balance => assert.equal(balance.valueOf(), toFixed(0)));		
	});
});
