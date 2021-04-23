// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./Context.sol";


/* @title Staking Pool Contract
 * Open Zeppelin Pausable  */

contract Stakingpool is Context,Initializable,ReentrancyGuard,Pausable{
  
  using SafeMath for uint;
  
  uint public StakePeriod;
  
  address private owner;

  IERC20 public MCHToken;
  IERC20 public MCFToken;
  
  
 /** @dev track total current stake yields of a user */
   mapping(address => uint) public currentstakeyields;
   
   /* @dev track Stakedbalances of user*/
  mapping(address => uint) public stakedBalances;
  
  /** @dev track StakedShares of user */
  mapping(address => uint) public stakedShares;
  
  /** @dev track total staked amount of tokens of all users */
  uint public totalStakedMcH;
  
  /** @dev track MCH value */
  uint public MCH;
  
  /** @dev track MCF value */
  uint public MCF;
  
  /** @dev track total staked value of all users */
  uint public totalStakedamount;
  
 /** @dev track Daily Rate of Investment */
 mapping(address => uint) public DROI;
  
 /** @dev track Monthly Rate of Investment */
  mapping(address => uint) public MROI;
  
 /** @dev track Annual Rate of Investment */ 
  mapping(address => uint) public ROI;
  
  /** @dev track claimable tokens */ 
  mapping(address => uint) public claimable;
  
  /** @dev track vested tokens */  
  mapping(address => uint) public vested;
  
   /** @dev track users
    * users must be tracked in this array because mapping is not iterable */
  address[] public users;
  
   /** @dev track index by address added to users */
  mapping(address => uint) private userIndex;
  
    /** @dev track stake time of users */
  mapping(address => uint) internal creationTime;
  
    /** @dev track whether users has completed stake period */
  mapping(address => bool) isFinalized;
  
    /** @dev track staked status of users */
  mapping(address => bool) Staked;
  
   /** @dev track staking status of users */
  mapping(address => bool) isStaking;
 
 /** @dev trigger notification of staked amount
    * @param sender       msg.sender for the transaction
    * @param amount       msg.value for the transaction
    */
  event NotifyStaked(address sender, uint amount);
  
  /** @dev trigger notification of unstaked amount
    * @param sender       msg.sender for the transaction
    * @param amount       msg.value for the transaction
    */
  event NotifyUnStaked(address sender, uint amount);


  // @dev trigger notification of claimed amount
  event Notifyclaimed(address sender,uint Balance);
  
  // modifiers
 
  modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
  
     /**
     * @dev Throws if called before stakingperiod
     */
    modifier onlyAfter() {
        
      require(block.timestamp >= creationTime[msg.sender].add(StakePeriod) ,"StakePeriod not completed");
      _;
   }
   

 // @dev contract Initializable
    
    function Initialize (address _MCHToken, address _MCFToken) public initializer {
    
     MCHToken = IERC20(_MCHToken);
     MCFToken = IERC20(_MCFToken);
     owner = msg.sender;
     StakePeriod = 11 days;
    
    }

  /** @dev test if user is in current user list
    * @param user address of user to test if in list
    * @return true if user is on record, otherwise false
    */
  function isUser(address user) internal view
       returns(bool, uint256)
   {
       for (uint256 i = 0; i < users.length; i += 1){
           if (user == users[i]) return (true, i);
       }
       return (false, 0);
   }
    
    /** @dev add a user to users array
    * @param user address of user to add to the list
    */
  
   function addUser(address user) internal
   {
       (bool _isUser, ) = isUser(user);
       if(!_isUser) users.push(user);
   }
   
   /** @dev remove a user from users array
    * @param user address of user to remove from the list
    */
    
   function removeUser(address user) internal
   {
       (bool isUser, uint256 i) = isUser(user);
       if(isUser){
           users[i] = users[users.length - 1];
           users.pop();
       }
   }

  
   /** @dev stake funds to PoolContract
    */
    function Approvestake(uint amount) external whenNotPaused {
     
      // staking amount cannot be zero
      require(amount > 0, "cannot be zero");
    
      // Transfer Mock  tokens to this contract for staking
      MCHToken.transferFrom(msg.sender, address(this), amount);
      
      // updating stakedBalances
      stakedBalances[msg.sender] = stakedBalances[msg.sender].add(amount);
      
      // updating total stakedBalances
      uint shares = (stakedBalances[msg.sender].mul(100)).div(totalStakedMcH.add(amount));
      
      // updating stakedShares
      stakedShares[msg.sender] = stakedShares[msg.sender].add(shares);
      
      // Adding staker to users Array only if not staked early 
       if(!Staked[msg.sender]) {
          
            addUser(msg.sender);
          
             // storing the start stake time of user
            creationTime[msg.sender] = block.timestamp;
          
        }  
      
      // updating status of the staking
       isStaking[msg.sender] = true;
       Staked[msg.sender] = true;
       
      
      // triggering event 
      emit NotifyStaked(msg.sender, amount);
   }
}