pragma solidity >=0.4.0;

//import 'app/node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol';

//    function add(uint256 a, uint256 b) internal pure returns (uint256) {
//       uint256 c = a + b;
//        require(c >= a, "SafeMath: addition overflow");
//
//       return c;
//   }

//function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//        require(b <= a, errorMessage);
//        uint256 c = a - b;
//
//        return c;
//    }


contract Series{
    
//    using SafeMath for uint;
    string public title;
    uint public pledgeperEpisode;
    uint public minimumPublicationPeriod;

    mapping(address => uint) public pledges;
    address[] pledgers;
    uint public lastPublicationBlock;
    mapping(uint => string) public publishedEpisodes;
    uint public episodeCounter;

    address owner;

    event NewPledger(address pledger);
    event NewPledge(address indexed pledger, uint pledge, uint totalPledge);
    event NewPublication(uint episodeId, string episodeLink, uint episodePay);
    event Withdrawal(address indexed pledger, uint pledge);
    event PledgeInsufficient(address indexed pledger, uint pledge);
    event SeriesClosed(uint balanceBeforeClose);    

    modifier only_owner() {
        require(msg.sender == owner);
        _;
    }

    
    constructor (string memory _title, uint _pledgeperEpisode, uint _minimumPublicationPeriod) public {
        owner = msg.sender;
        title = _title;
        pledgeperEpisode = _pledgeperEpisode;
        minimumPublicationPeriod = _minimumPublicationPeriod;    
	
    }

function pledge() public payable {
    require(msg.value + pledges[msg.sender] >= pledgeperEpisode, "Pledge must be greater than minimum pledge per episode");
    require(msg.sender != owner, "Owner cannot pledge on its own series");

    bool oldPledger = false;
    for(uint i=0; i<pledgers.length;i++ )
    {
        if(pledgers[i] == msg.sender) {
            oldPledger = true;
            break;
        }
    }
    if(!oldPledger) {
        pledgers.push(msg.sender);
        emit NewPledger(msg.sender);
    }
    pledges[msg.sender] = pledges[msg.sender]+msg.value;
    emit NewPledge(msg.sender,msg.value,pledges[msg.sender]);

}

function withdraw() public {
    uint amount = pledges[msg.sender];
    if (amount > 0) {
        pledges[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit Withdrawal(msg.sender,amount);
        emit PledgeInsufficient(msg.sender,0);
    }    

}

function publish (string memory episodeLink) public only_owner {
    require(lastPublicationBlock == 0 || block.number > lastPublicationBlock + minimumPublicationPeriod,
    "Owner cannot publish again so soon");
    lastPublicationBlock = block.number;
    episodeCounter++;
    publishedEpisodes[episodeCounter] = episodeLink;

    uint episodePay = 0;
    for (uint i=0; i < pledgers.length;i++)
    {
        if(pledges[pledgers[i]] >= pledgeperEpisode) {
        pledges[pledgers[i]] = pledges[pledgers[i]] - pledgeperEpisode;
        episodePay = episodePay + pledgeperEpisode;
        if(pledges[pledgers[i]]<pledgeperEpisode){
            emit PledgeInsufficient(pledgers[i],pledges[pledgers[i]]);
        }
        }
    }
    owner.transfer(episodePay);
    emit NewPublication(episodeCounter,episodeLink,episodePay);
}

function close() public only_owner {
    uint contractBalance = address(this).balance;
    for (uint i=0; i< pledgers.length;i++){
        uint amount = pledges[pledgers[i]];
        if(amount>0) {
            pledgers[i].transfer(amount);
        }
    }
        emit SeriesClosed(contractBalance);
        selfdestruct(owner);
}

function totalPledgers() public view returns(uint) {
    return pledgers.length;
}

function activePledgers() public view returns(uint) {
    uint active = 0;
    for(uint i=0; i< pledgers.length;i++)
    {
        if(pledges[pledgers[i]] >= pledgeperEpisode) {
            active++;
        }
    }
    return active;
}
function nextEpisodePay() public view returns(uint) {
    uint episodePay=0;
    for(uint i = 0; i < pledgers.length; i++ ){
        if(pledges[pledgers[i]] >= pledgeperEpisode) {
            episodePay = episodePay + pledgeperEpisode;
        }
    }
    return episodePay;
}

}
