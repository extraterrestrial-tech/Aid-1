
const Aid1 = artifacts.require("Aid1_Testing");

const DummyCoin1 = artifacts.require("DummyCoin1");
const DummyCoin2 = artifacts.require("DummyCoin2");
const DummyCoin3 = artifacts.require("DummyCoin3");

const ownerAddress = "0x627306090abab3a6e1400e9345bc60c78a8bef57";
const otherAddress1 = "0x5aeda56215b167893e80b4fe645ba6d5bab767de";
const otherAddress2 = "0x6330a553fc93768f612722bb8c2ec78ac90b3bbc";
const otherAddress3 = "0x0f4f2ac550a1b4e2280d04c21cea7ebd822934b5";
const bogusAddress = "0x0f4f2ac550a1b4e2280d04c21cea7ebd00000000";

const dummyCoinTotalSupply = 100000000;

const expectedTotalSupply = (1700000 + 1800000 + 1900000) * 1.09; // 5886000
const expectedOwnerShare = (1700000 + 1800000 + 1900000) * 0.09; // 486000

const share1 = 1700000;
const share2 = 1800000;
const share3 = 1900000;

const decimalPlaces = 18;

function forInstance(msg, cb) {

	var pa = [
		Aid1.deployed(),
		DummyCoin1.deployed(),
		DummyCoin2.deployed(),
		DummyCoin3.deployed()
	];

	return it(msg, () => Promise.all(pa).then(ia => cb(...ia)) );
}

function toFixed(a) {
	return Math.floor(a * Math.pow(10, decimalPlaces));
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

function floorTo8(d) {
	return Math.floor(d * 100000000) / 100000000;
}

function setupAgreement(aid1, tokenInstance, toAddress, sendAmount, receiveAmount) {
	return Promise.resolve()
	.then(() => tokenInstance.transfer(toAddress, toFixed(receiveAmount)))
	.then(() => tokenInstance.transfer(bogusAddress, toFixed(dummyCoinTotalSupply - receiveAmount)))
	.then(() => tokenInstance.approve(aid1.address, toFixed(receiveAmount), { from: toAddress }))
	.then(() => tokenInstance.allowance(toAddress, aid1.address))
	.then(allowance => assert.equal(allowance.valueOf(), toFixed(receiveAmount)))

	.then(() => aid1.setupAgreement(tokenInstance.address, toAddress, toFixed(sendAmount), toFixed(receiveAmount)))
	.then(() => tokenInstance.balanceOf(aid1.address))
	.then(balance => assert.equal(balance.valueOf(), toFixed(receiveAmount)))
	.then(() => aid1.balanceOf(toAddress))
	.then(balance => assert.equal(balance.valueOf(), toFixed(sendAmount)))	
}

function testCashOut(aid1, dc, total) {
	return Promise.resolve()
	.then(() => aid1.cashOut(dc.address))
	.then(() => dc.balanceOf(ownerAddress))
	.then(balance => assert.equal(floorTo8(toFloat(balance.valueOf())), floorTo8(total * expectedOwnerShare / expectedTotalSupply)) )
	.then(() => dc.balanceOf(otherAddress1))
	.then(balance => assert.equal(floorTo8(toFloat(balance.valueOf())), floorTo8(total * share1 / expectedTotalSupply)) )
	.then(() => dc.balanceOf(otherAddress2))
	.then(balance => assert.equal(floorTo8(toFloat(balance.valueOf())), floorTo8(total * share2 / expectedTotalSupply)) )
	.then(() => dc.balanceOf(otherAddress3))
	.then(balance => assert.equal(floorTo8(toFloat(balance.valueOf())), floorTo8(total * share3 / expectedTotalSupply)) );
}

function testCashOutEther(aid1) {
	const etherSent = 10000000000000000000;
	const initialBalance1 = 1 * web3.eth.getBalance(otherAddress1).valueOf();
	const initialBalance2 = 1 * web3.eth.getBalance(otherAddress2).valueOf();
	const initialBalance3 = 1 * web3.eth.getBalance(otherAddress3).valueOf();

	return aid1.send(etherSent)
	.then(() => aid1.cashOutEther())
	.then(() => assert.equal(
		web3.eth.getBalance(otherAddress1).valueOf(), 
		initialBalance1 + etherSent * share1 / expectedTotalSupply))
	.then(() => assert.equal(
		web3.eth.getBalance(otherAddress2).valueOf(), 
		initialBalance2 + etherSent * share2 / expectedTotalSupply))
	.then(() => assert.equal(
		web3.eth.getBalance(otherAddress3).valueOf(), 
		initialBalance3 + etherSent * share3 / expectedTotalSupply));
}

contract('Aid1', () => {
	return forInstance('Scenario 1', (aid1, dc1, dc2, dc3) => {
		return Promise.resolve()
		.then(() => setupAgreement(aid1, dc1, otherAddress1, share1, 700000))
		.then(() => setupAgreement(aid1, dc2, otherAddress2, share2, 800000))
		.then(() => setupAgreement(aid1, dc3, otherAddress3, share3, 900000))

		.then(() => aid1.lock())
		.then(() => aid1.state())
		.then(state => assert.equal(state, 1))
		.then(() => aid1.totalSupply())
		.then(totalSupply => assert.equal(totalSupply.valueOf(), toFixed(expectedTotalSupply)))
		.then(() => aid1.balanceOf(ownerAddress))
		.then(balance => assert.equal(balance.valueOf(), toFixed(expectedOwnerShare)))

		.then(() => aid1.unlock())
		.then(() => aid1.state())
		.then(state => assert.equal(state, 2))

		.then(() => testCashOutEther(aid1))

		.then(() => testCashOut(aid1, dc1, 700000))
		.then(() => testCashOut(aid1, dc2, 800000))
		.then(() => testCashOut(aid1, dc3, 900000))
	});	
});
