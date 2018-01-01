pragma solidity ^0.4.4;

import './SafeMath.sol';
import './ERC20Interface.sol';

contract Aid1 is ERC20Interface {

	using SafeMath for uint256;

	// ERC20 stuff

	uint256 public totalSupply = 218000000000000000000000000; // 238,000,000.00
	string public constant name = "Aid-1";
	string public constant symbol = "AID1";
	uint8 public constant decimals = 18;

	mapping(address => uint256) private balances;
	mapping(address => mapping (address => uint256)) private allowed;
	mapping(address => mapping (address => uint256)) private cashOutMap;
 
	// Owner

	address private owner;

	// Re-entry protection 

	bool private entryLock = false;

	// Contract parameters

	uint8 public constant ownerTokens = 9;
	uint256 public releaseTime = 1729641600; // October 23 2024
	uint256 public sendAmount = 1000000000000000000000000; // 1,000,000.00 tokens
	uint256 public payoutMinimum = 1000000000000000000; // 1 token

	// Contract variables

	uint8 public state = 0; // 0 = SETUP   1 = LOCKED   2 = UNLOCKED
	address[] public tokenAddresses;
	mapping(address => bool) tokenAddressesMap;

	address[] public tokenHolders;
	mapping(address => bool) tokenHoldersMap;


	// ************************************************************************
	//
	// Constructor
	//
	// ************************************************************************	

	function Aid1() public {
		owner = msg.sender;
		balances[owner] = totalSupply;
	}

	// ************************************************************************
	//
	// Modifiers
	//
	// ************************************************************************	

	modifier noReentry() {
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

	event Transfer(address indexed _from, address indexed _to, uint256 _amount);
	event Approval(address indexed _owner, address indexed _spender, uint256 _amount);	

	function balanceOf(address _addr) public view returns(uint256 balance) {

		require(_addr != address(0));

		return balances[_addr];
	}

	function transfer(address _to, uint256 _amount) public returns(bool sucess) {

		require(_to != address(0));
		require(_amount > 0);
		require(_amount <= balances[msg.sender]);
		require(balances[_to] + _amount > balances[_to]);

		balances[msg.sender] = balances[msg.sender].sub(_amount);
		balances[_to] = balances[_to].add(_amount);

		if(tokenHoldersMap[_to] == false) {
			tokenHolders.push(_to);
			tokenHoldersMap[_to] = true;
		}

		Transfer(msg.sender, _to, _amount);

		return true;
	}	

 	function transferFrom(address _from, address _to, uint _amount) public returns(bool sucess) {

		require(_from != address(0));
		require(_to != address(0));
		require(_amount > 0);
		require(_amount <= balances[_from]);
		require(_amount <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_amount);
		balances[_to] = balances[_to].add(_amount);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);

		if(tokenHoldersMap[_to] == false) {
			tokenHolders.push(_to);
			tokenHoldersMap[_to] = true;
		}

		Transfer(_from, _to, _amount);

		return true;
 	}

 	function approve(address _spender, uint _amount) public returns(bool success) {

		require(_spender != address(0));
		require(_amount > 0);
		require(_amount <= balances[msg.sender]);

		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);

		return true;
 	}

	function allowance(address _owner, address _spender) public view returns(uint256 remaining) {

		require(_owner != address(0));
		require(_spender != address(0));

		return allowed[_owner][_spender];
	}

	// Non-ERC20

	function() public payable { }

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
			uint256 _sendAmount,
			uint256 _receiveAmount
			) external onlyState(0 /* SETUP */) ownerOnly noReentry returns(bool) {

		require(_tokenAddress != address(0));
		require(_to != address(0));
		require(sendAmount <= balances[owner]);
		require(_sendAmount >= sendAmount);

		if(tokenAddressesMap[_tokenAddress] == false) {
			tokenAddresses.push(_tokenAddress);
			tokenAddressesMap[_tokenAddress] = true;
		}

		balances[owner].sub(_sendAmount);
		balances[_to].add(_sendAmount);

		if(_receiveAmount > 0) {
			return ERC20Interface(_tokenAddress).transferFrom(_to, this, _receiveAmount);	
		}

		return true;	
	}

	function lock() external onlyState(0 /* SETUP */) ownerOnly returns(bool) {

		state = 1 /* LOCKED */;
		totalSupply.sub(balances[owner]);
		balances[owner] = totalSupply.mul(ownerPercent).div(100);
		totalSupply.add(balances[owner]);

		return true;
	}

	// ************************************************************************
	//
	// Methods for state LOCKED
	//
	// ************************************************************************	

	function registerToken(
			address _tokenAddress) external onlyState(1 /* LOCKED */) noReentry returns(bool) {

		require(_tokenAddress != address(0));

		if(tokenAddressesMap[_tokenAddress] == false) {
			tokenAddresses.push(_tokenAddress);
			tokenAddressesMap[_tokenAddress] = true;
		}

		return true;	
	}
	
	function unlock() external onlyState(1 /* LOCKED */) returns(bool) {
		require(releaseTime <= block.timestamp);

		state = 2 /* UNLOCKED */;

		return true;
	}

	// ************************************************************************
	//
	// Methods for state UNLOCKED
	//
	// ************************************************************************

	function cashOutEther() external onlyState(2 /* UNLOCKED */) noReentry returns(bool) {

		uint256 total = this.balance;
		if(total > 0) {
			for(uint index = 0; index < tokenHolders.length; index++) {
				address tokenHolder = tokenHolders[index];
				if(balances[tokenHolder] >= payoutMinimum) {
					uint256 sum = total.mul(balances[tokenHolder]).div(totalSupply);
					tokenHolder.send(sum);
				}
			}
		}

		return true;
	}

	function cashOut(
		address _tokenAddress) external onlyState(2 /* UNLOCKED */) noReentry returns(bool) {
		
		uint256 total = getTokensHeld(_tokenAddress);
		if(total > 0) {
			for(uint index = 0; index < tokenHolders.length; index++) {
				address tokenHolder = tokenHolders[index];
				if(balances[tokenHolder] >= payoutMinimum) {
					uint256 sum = total.mul(balances[tokenHolder]).div(totalSupply);
					ERC20Interface(_tokenAddress).transfer(tokenHolder, sum);				
				}
			}			
		}

		return true;
	}
}
