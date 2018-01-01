# Aid-1

## Acceptance Criteria

### Parameters
* ownerPercent = 9
* releaseTime = 10/23/2024
* sendAmount = 1,000,000 tokens
* payoutMinimum = 1 token

### ERC20 token
* Symbol “AID1”
* 18 decimal digits
* Contract should be payable
* Manage a unique list of all token holders

### At creation
* Owner should have 218,000,000 tokens
* State should be SETUP
* Total supply is 218,000,000 tokens

### During state SETUP
* Method setupAgreement
  * Can only be called by owner
  * Receives parameters:
    * _tokenAddress: address of other token smart contract
    * _to: wallet address of partner
    * _sendAmount: how many tokens to send
    * _receiveAmount: how many tokens to receive
    *  Send _sendAmount tokens from owner to address _to
    * _sendAmount should be >= sendAmount
  * If _receiveAmount > 0 cause other contract to transfer _receiveAmount tokens to this contract
  * Add token address to token list (unique)
  
* Method lock
  * Can only be called during state SETUP
  * Can only be called by owner
  * Destroy owner’s tokens
  * Create ownerPercent of total tokens sent, give it to owner
  * Change state to LOCKED

### During state LOCKED
* Method registerToken
  * Can be called by anybody
  * Receive parameters
    * _tokenAddress: address of token smart contract
* Add token address to token list (unique)
* Method unlock
* If after releaseTime
* Can be called by anybody
* Change state to UNLOCKED
* During state UNLOCKED
* Method cashOutEther
* Can be called by anybody
* Distribute ether balance between all token holders on pro rata basis
* Only send to token owners who own >= payoutMinimum tokens
* Method cashOut
* Can be called by anybody
* Receive parameters
* _tokenAddress: address of token smart contract
* Distribute token balance between all token holders on pro rata basis
* Only send to token owners who own >= payoutMinimum tokens




