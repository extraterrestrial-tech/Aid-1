
const Aid1 = artifacts.require("Aid1");
const Aid1_Testing = artifacts.require("Aid1_Testing");
const ownerAddress = "0x627306090abab3a6e1400e9345bc60c78a8bef57";
const otherAddress1 = "0x5aeda56215b167893e80b4fe645ba6d5bab767de";
const otherAddress2 = "0x6330a553fc93768f612722bb8c2ec78ac90b3bbc";
const decimalPlaces = 18;

function forInstance(msg, aid1, cb) {
	return it(msg, () => aid1.deployed().then(cb));
}

function toFixed(a) {
	return a * Math.pow(10, decimalPlaces);
}

function toFloat(a) {
	return Math.floor(a / Math.pow(10, decimalPlaces));
}

function expectToThrow(cb) {
	var flag = false;
	return cb()
	.catch(() => { flag = true; return assert(true); } )
	.then(() => { if(!flag) return assert(false); });
}

function testTransfer(instance) {
	return instance.transfer(otherAddress1, toFixed(1))
	.then(flag => assert(flag))
	.then(() => instance.balanceOf.call(otherAddress1))
	.then(balance => assert.equal(balance.valueOf(), toFixed(1)))
	.then(() => instance.transfer(ownerAddress, toFixed(1), { from: otherAddress1 }))
	.then(flag => assert(flag))
	.then(() => instance.balanceOf.call(otherAddress1))
	.then(balance => assert.equal(balance.valueOf(), 0));			
}

contract('at creation', () => {

	forInstance('owner should own 219,000,000 tokens', Aid1, instance => {
		return instance.balanceOf.call(ownerAddress)
		.then(balance => assert.equal(balance.valueOf(), toFixed(219000000)));
	});	

	forInstance('state should be 0 (SETUP)', Aid1, instance => {
		return instance.state()
		.then(state => assert.equal(state.valueOf(), 0));
	});	
});

contract('State = 0 (SETUP)', () => {

	forInstance('anybody may transfer tokens', Aid1, instance => testTransfer(instance));

	forInstance('should not be possible to call unlock', Aid1, instance => {
		return expectToThrow(() => instance.unlock());
	});

	forInstance('should not be possible to call cashOut', Aid1, instance => {
		return expectToThrow(() => instance.cashOut());
	});

	forInstance('should not be possible to call cashOutEther', Aid1, instance => {
		return expectToThrow(() => instance.cashOutEther());
	});
});

contract('State = 1 (LOCKED)', () => {

	forInstance('after lock is called, state should be 1 (LOCKED)', Aid1, instance => {
		return instance.transfer(otherAddress2, toFixed(1000000))
		.then(() => instance.lock())
		.then(() => instance.state())
		.then(state => assert.equal(state.valueOf(), 1 /* LOCKED */));
	});	

	forInstance('anybody may transfer tokens', Aid1, instance => testTransfer(instance));

	forInstance('should not be possible to call cashOut', Aid1, instance => {
		return expectToThrow(() => instance.cashOut());
	});

	forInstance('should not be possible to call cashOutEther', Aid1, instance => {
		return expectToThrow(() => instance.cashOutEther());
	});

});

contract('State = 2 (UNLOCKED)', () => {

	forInstance('should not be possible to call unlock unless interval has expired', Aid1, instance => {
		return instance.transfer(otherAddress2, toFixed(1000000))
		.then(() => instance.lock())
		.then(() => expectToThrow(() => instance.unlock()));
	});

	forInstance('after unlock is called, state should be 2 (UNLOCKED)', Aid1_Testing, instance => {
		return instance.lock()
		.then(() => instance.unlock())
		.then(() => instance.state())
		.then(state => assert.equal(state.valueOf(), 2 /* UNLOCKED */));
	});	

	forInstance('anybody may transfer tokens', Aid1, instance => testTransfer(instance));
});
