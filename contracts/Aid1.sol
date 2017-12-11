pragma solidity ^0.4.4;

// DO NOT DEPLOY THIS CODE. IT IS BOT FINISHED AND NOT SECURE!!!!!!!

import './SafeMath.sol';
import './ERC20Interface.sol';

contract Aid1 is ERC20Interface {

	using SafeMath for uint256;

	// ERC20 stuff

	uint256 public _totalSupply = 238000000000000000000000000; // 238,000,000.00
	string public constant name = "Aid-1";
	string public constant symbol = "AID1";
	uint8 public constant decimals = 18;

	mapping(address => uint256) public balances;
	mapping(address => mapping (address => uint256)) public allowed;
 
	// Owner

	address public owner;

	// Re-entry protection 

	bool public entryLock = false;

	// Contract parameters

	uint8 public ownerPercent = 10;
	uint256 public lockInterval = 7 years;

	// Contract variables

	uint8 public state = 0; // 0 = SETUP   1 = locked   2 = unlocked
	uint256 public lockTime;
	mapping(address => address) public toAddressByTokenAddress;
	address[] public tokenAddresses;

	// ************************************************************************
	//
	// Constructor
	//
	// ************************************************************************	

	function Aid1() public {
		owner = msg.sender;
		balances[owner] = _totalSupply;
	}

	// ************************************************************************
	//
	// Modifiers
	//
	// ************************************************************************	

	modifier noRentry() {
		require(entryLock == false);
		entryLock = true;
		_;
		entryLock = false;
	}

	modifier ownerOnly() {
		require(msg.sender == owner);
		_;
	}

	modifier onlyState(uint _state) {
		require(state == _state);
		_;
	}

	// ************************************************************************
	//
	// Methods for all states
	//
	// ************************************************************************	

	// ERC20 stuff

	function balanceOf(address _addr) public view returns(uint256 balance) {
		return balances[_addr];
	}

	function totalSupply() public view returns(uint256) {
 		return _totalSupply;
 	}

	event Transfer(address indexed _from, address indexed _to, uint256 _amount);
	event Approval(address indexed _owner, address indexed _spender, uint256 _amount);	

	function transfer(address _to, uint256 _amount) public returns(bool sucess) {
		require(_to != address(0));
		require(_amount > 0);
		require(_amount <= balances[msg.sender]);
		require(balances[_to] + _amount > balances[_to]);

		balances[msg.sender] = balances[msg.sender].sub(_amount);
		balances[_to] = balances[_to].add(_amount);

		Transfer(msg.sender, _to, _amount);

		return true;
	}	

 	function transferFrom(address _from, address _to, uint _amount) public returns(bool sucess) {
		require(_to != address(0));
		require(_amount > 0);
		require(_amount <= balances[_from]);
		require(_amount <= allowed[_from][msg.sender]);
		require(balances[_to] + _amount > balances[_to]);

		balances[_from] = balances[_from].sub(_amount);
		balances[_to] = balances[_to].add(_amount);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);

		Transfer(_from, _to, _amount);

		return true;
 	}

 	function approve(address _spender, uint _amount) public returns(bool success) {
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);

		return true;
 	}

	function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
		return allowed[_owner][_spender];
	}

	// Non-ERC20

 	function getTokensHeld(address _tokenAddress) public view returns(uint256) {

 		require(_tokenAddress != address(0));

		return ERC20Interface(_tokenAddress).balanceOf(address(this));
	}


	// ************************************************************************
	//
	// Methods for state SETUP
	//
	// ************************************************************************	


	function setupAgreement(
			address _tokenAddress,
			address _to, 
			uint256 _sendAmount) public onlyState(0 /* SETUP */) ownerOnly noRentry returns(bool) {

		require(_tokenAddress != address(0));
		require(_to != address(0));
		require(_sendAmount > 0);
		require(_sendAmount <= balances[owner]);

		tokenAddresses.push(_tokenAddress);
		toAddressByTokenAddress[_tokenAddress] = _to;

		balances[owner].sub(_sendAmount);
		balances[_to].add(_sendAmount);

		return true;
	}

	function cancelAgreement(
			address _tokenAddress) public onlyState(0 /* SETUP */) ownerOnly noRentry returns(bool) {

		require(_tokenAddress != address(0));

		address toAddresss = toAddressByTokenAddress[_tokenAddress];

		require(toAddresss != address(0));
		require(balances[toAddresss] > 0);

		balances[owner].add(balances[toAddresss]);
		balances[toAddresss] = 0;

		uint256 amount = getTokensHeld(_tokenAddress);
		ERC20Interface(_tokenAddress).transfer(toAddresss, amount);

		return true;
	}

	function returnTokens(
		address _tokenAddress,
		address _to,
		uint256 _amount) public onlyState(0 /* SETUP */) ownerOnly noRentry returns(bool) {
		
		require(_to != address(0));

		return ERC20Interface(_tokenAddress).transfer(_to, _amount);
	}

	function lock() public onlyState(0 /* SETUP */) ownerOnly returns(bool) {

		state = 1 /* LOCKED */;
		_totalSupply.sub(balances[owner]);
		balances[owner] = _totalSupply.mul(ownerPercent).div(100);
		_totalSupply.add(balances[owner]);

		lockTime = block.timestamp;

		return true;
	}

	// ************************************************************************
	//
	// Methods for state LOCKED
	//
	// ************************************************************************	

	function unlock() public onlyState(1 /* LOCKED */) returns(bool) {
		require(lockTime.add(lockInterval) <= block.timestamp);

		state = 2 /* UNLOCKED */;

		return true;
	}

	// ************************************************************************
	//
	// Methods for state UNLOCKED
	//
	// ************************************************************************	

	function cashOut(
		uint256 _amount, 
		address[] _additionalTokens) public onlyState(2 /* UNLOCKED */) noRentry returns(bool) {
		
		require(_amount <= balances[msg.sender]);
		require(_amount > 0);

		uint256 totalSupplySaved = _totalSupply;

		_totalSupply.sub(_amount);
		balances[msg.sender] = balances[msg.sender].sub(_amount);

		// withdraw share of whatever ether the contract has accrued
		uint256 etherSum = _amount.mul(this.balance).div(totalSupplySaved);
		if(etherSum >= this.balance) {
			msg.sender.send(etherSum);
		}

		address tokenAddress;
		uint256 sum;
		uint index;

		// withdraw tokens of each kind
		for(index = 0; index < tokenAddresses.length; index++) {
			tokenAddress = tokenAddresses[index];
			sum = getTokensHeld(tokenAddress);
			if(sum > 0) {
				sum = sum.mul(_amount).div(totalSupplySaved);
				ERC20Interface(tokenAddress).transfer(msg.sender, sum);
			}
		}

		// withdraw tokens of each kind of additional tokens supplied by caller
		for(index = 0; index < _additionalTokens.length; index++) {
			tokenAddress = _additionalTokens[index];
			sum = getTokensHeld(tokenAddress);
			if(sum > 0) {
				sum = sum.mul(_amount).div(totalSupplySaved);
				ERC20Interface(tokenAddress).transfer(msg.sender, sum);
			}
		}

		return true;
	}
}
