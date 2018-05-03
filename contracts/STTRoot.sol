pragma solidity ^0.4.4;

import './SafeMath.sol';
import './ERC20Interface.sol';

contract STTInterface is ERC20Interface {
	function getPrice() public constant returns(uint256);
	function getAveragePriceForSell(uint256 _amount) public constant returns(uint256);
	function getAveragePriceForBuy(uint256 _amount) public constant returns(uint256);
	function sellTokens(uint256 _amount, address recipient) external returns(bool);
	function buyTokens(address recipient) external payable returns(bool);
}

contract STTRoot is STTInterface {

	using SafeMath for uint256;

	// ERC20 stuff

	uint256 public totalSupply = 0;
	string public name = "STT";
	string public symbol = "STT";
	uint8 public constant decimals = 18;
	uint256 public constant fixedOne = 1000000000000000000;

	mapping(address => uint256) private balances;
	mapping(address => mapping (address => uint256)) private allowed;
 
	// Owner

	address private owner;
	bool initialized = false;

	// Re-entry protection 

	bool private entryLock = false;

	// Self Tradable Parameters

	uint8 public W = 5;
	uint256 public D = 1;

	// ************************************************************************
	//
	// Constructor and initializer
	//
	// ************************************************************************	

	function STT() public {
		owner = msg.sender;
	}

	function initialize(string _name, string _symbol, uint8 _W, uint256 _D) external ownerOnly {

		require(!initialized);

		initialized = true;

		name = _name;
		symbol = _symbol;
		W = _W;
		D = _D;
	}

	// ************************************************************************
	//
	// Modifiers
	//
	// ************************************************************************	

	modifier ownerOnly() {
		require(msg.sender == owner);
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

	function balanceOf(address _addr) external constant returns(uint256 balance) {

		require(_addr != address(0));

		return balances[_addr];
	}

	function transfer(address _to, uint256 _amount) external returns(bool sucess) {

		require(_to != address(0));
		require(_amount > 0);
		require(_amount <= balances[msg.sender]);
		//require(balances[_to] + _amount > balances[_to]);

		balances[msg.sender] = balances[msg.sender].sub(_amount);
		balances[_to] = balances[_to].add(_amount);

		Transfer(msg.sender, _to, _amount);

		return true;
	}	

 	function transferFrom(address _from, address _to, uint256 _amount) external returns(bool sucess) {

		require(_from != address(0));
		require(_to != address(0));
		require(_amount > 0);
		require(_amount <= balances[_from]);
		require(_amount <= allowed[_from][_to]);

		balances[_from] = balances[_from].sub(_amount);
		balances[_to] = balances[_to].add(_amount);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);

		Transfer(_from, _to, _amount);

		return true;
 	}

 	function approve(address _spender, uint256 _amount) external returns(bool success) {

		require(_spender != address(0));
		require(_amount >= 0);
		require(_amount <= balances[msg.sender]);

		allowed[msg.sender][_spender] = _amount;

		Approval(msg.sender, _spender, _amount);

		return true;
 	}

	function allowance(address _owner, address _spender) external constant returns(uint256 remaining) {

		require(_owner != address(0));
		require(_spender != address(0));

		return allowed[_owner][_spender];
	}

	// Non-ERC20

	function changeOwner(address newOwner) external ownerOnly {
		owner = newOwner;
	}

	// Self Tradable Functionality

	function getReserve() public constant returns(uint256) {

		return this.balance;
	}

	function() public payable {
	}

	function power(uint256 _a, uint8 _n) pure public returns(uint256) {

        require(_n > 1 && _n < 10);

        uint256 a = _a;

		for(uint i=1; i<_n; i++) {
			a = (a * _a) / fixedOne;
		}
		return a;
	}

    function root(uint _a, uint8 _n) pure public returns(uint256) {
        
        require(_n > 1 && _n < 10);

        uint256 x = (fixedOne + _a) / 2;
        while(true) {
        	uint256 t = power(x, _n);
        	if(t == _a) {
        		return x;
        	}
        	x = x - (power(x, _n) - _a) / (_n * power(x, _n - 1);  
        }
    }

	function RfromS(uint256 _S) private constant returns(uint256) {

		return power(_S, W) / D;
	}

	function SfromR(uint256 _R) private constant returns(uint256) {

		return root(_R, W) * D;
	}

	function getPrice() public constant returns(uint256) {

		return W * getReserve() / totalSupply;
	}

	function getAveragePriceForSell(uint256 _amount) public constant returns(uint256) {

		return fixedOne * (getReserve() - RfromS(totalSupply - _amount)) / _amount;
	}

	function getAveragePriceForBuy(uint256 _amount) public constant returns(uint256) {

		return fixedOne * (RfromS(totalSupply - _amount) - getReserve()) / _amount;
	}

	function sellTokens(uint256 _amount, address recipient) external returns(bool) {

		require(balances[msg.sender] >= _amount);

		uint256 deltaR = getAveragePriceForSell(_amount) * _amount;
		balances[msg.sender] -= _amount;
		totalSupply -= _amount;

		recipient.send(deltaR);

		return true;
	}

	function buyTokens(address recipient) external payable returns(bool) {

		uint256 newS;

		require(msg.value > 0);

		newS = SfromR(this.balance + msg.value);
		balances[msg.sender] = balances[recipient] + newS;
		totalSupply += newS;

		return true;
	}
}
