//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address, uint) external returns (bool);

    function transferFrom(
        address,
        address,
        uint
    ) external returns (bool);
}

contract GuessBigSmall {
    IERC20 public immutable token;
    constructor(address _token){
        token=IERC20(_token);
    }
    mapping(address=>uint) public bigBalances;
    address[] public bigAddresses;
    uint public bigAllBalance;
    mapping(address=>uint) public smallBalances;
    address[] public smallAddresses;
    uint public smallAllBalance;
    bool public started;
    uint8 private status;
    uint32 public startTime;
    uint8 public random;
    function getStatus() public view returns(uint8) {
        if(!started){
            return 0;
        }else if(block.timestamp<startTime+ 5 minutes){
            return 1;
        }else {
            return 2;
        }
    }
    function start() external {
        require(!started,"already start");
        started=true;
        startTime=uint32(block.timestamp);
    }

    function guessBig(uint _amount) external {
        require(getStatus()==1,"not allow guess");
        require(msg.sender==tx.origin,"contract not allowed");
        token.transferFrom(msg.sender,address(this),_amount);
        bigBalances[msg.sender]+=_amount;
        bigAllBalance+=_amount;
        bigAddresses.push(msg.sender);
    }

    function guessSMall(uint _amount) external {
        require(getStatus()==1,"not allow guess");
        require(msg.sender==tx.origin,"contract not allowed");
        token.transferFrom(msg.sender,address(this),_amount);
        smallBalances[msg.sender]+=_amount;
        smallAllBalance+=_amount;
        smallAddresses.push(msg.sender);
    }

    function settle() external{
        require(getStatus()==2,"not allow settle");
        require(msg.sender==tx.origin,"contract not allowed");
        random=uint8(uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender,smallAllBalance,bigAllBalance,smallAddresses.length,bigAddresses.length)))%10);
        if(random<5){
            if(smallAllBalance<bigAllBalance){
                for(uint i;i<smallAddresses.length;i++){
                    token.transfer(smallAddresses[i],2*smallBalances[smallAddresses[i]]);
                    delete smallBalances[smallAddresses[i]];
                }
                for(uint i;i<bigAddresses.length;i++){
                    token.transfer(bigAddresses[i],(bigAllBalance-smallAllBalance)*bigBalances[bigAddresses[i]]/bigAllBalance);
                    delete bigBalances[bigAddresses[i]];
                }
            }else{
                for(uint i;i<smallAddresses.length;i++){
                    token.transfer(smallAddresses[i],smallBalances[smallAddresses[i]]+bigAllBalance*smallBalances[smallAddresses[i]]/smallAllBalance);
                    delete smallBalances[smallAddresses[i]];                
                }
                for(uint i;i<bigAddresses.length;i++){
                    delete bigBalances[bigAddresses[i]];
                }
            }
        }else{
            if(bigAllBalance<smallAllBalance){
                for(uint i;i<bigAddresses.length;i++){
                    token.transfer(bigAddresses[i],2*bigBalances[bigAddresses[i]]);
                    delete bigBalances[bigAddresses[i]];
                }
                for(uint i;i<smallAddresses.length;i++){
                    token.transfer(smallAddresses[i],(smallAllBalance-bigAllBalance)*smallBalances[smallAddresses[i]]/smallAllBalance);
                    delete smallBalances[smallAddresses[i]];
                }
            }else{
                for(uint i;i<bigAddresses.length;i++){
                    token.transfer(bigAddresses[i],bigBalances[bigAddresses[i]]+smallAllBalance*bigBalances[smallAddresses[i]]/bigAllBalance);
                    delete bigBalances[bigAddresses[i]];
                }
                for(uint i;i<smallAddresses.length;i++){
                    delete smallBalances[smallAddresses[i]];
                }
            }
        }
        delete bigAddresses;
        delete bigAllBalance;
        delete smallAddresses;
        delete smallAllBalance;
        started=false;
    }
}