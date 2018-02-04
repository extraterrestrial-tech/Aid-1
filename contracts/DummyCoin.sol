pragma solidity ^0.4.4;

import './SafeMath.sol';
import './ERC20Interface.sol';

contract DummyCoin is ERC20Interface {

	using SafeMath for uint256;

	// ERC20 stuff

	uint256 public totalSupply = 100000000000000000000000000; // 100,000,000.00
	string public constant name = "DummyCoin";
	string public constant symbol = "DummyCoin";
	uint8 public constant decimals = 18;

	mapping(address => uint256) private balances;
	mapping(address => mapping (address => uint256)) private allowed;
	
	// Owner

	address private owner;

	// Re-entry protection 

	bool private entryLock = false;

	// ************************************************************************
	//
	// Constructor
	//
	// ************************************************************************	

	function DummyCoin() public {
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
		require(balances[_to] + _amount > balances[_to]);

		balances[msg.sender] = balances[msg.sender].sub(_amount);
		balances[_to] = balances[_to].add(_amount);

		Transfer(msg.sender, _to, _amount);

		return true;
	}	

 	function transferFrom(address _from, address _to, uint _amount) external returns(bool sucess) {

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

 	function approve(address _spender, uint _amount) external returns(bool success) {

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
}

contract DummyCoin1 is DummyCoin {}
contract DummyCoin2 is DummyCoin {}
contract DummyCoin3 is DummyCoin {}
