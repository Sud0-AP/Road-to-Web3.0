// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// This import includes functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// Dev imports
import "hardhat/console.sol";


contract MemeLott is ERC721, ERC721Enumerable, ERC721URIStorage, KeeperCompatibleInterface, Ownable, VRFConsumerBaseV2  {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    AggregatorV3Interface public pricefeed;

    // VRF
    VRFCoordinatorV2Interface public COORDINATOR;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    uint32 public callbackGasLimit = 500000; // set higher as fulfillRandomWords is doing a LOT of heavy lifting.
    uint64 public s_subscriptionId;
    bytes32 keyhash =  0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15; 
    
    uint public /* immutable */ interval; 
    uint public lastTimeStamp;
    int256 public currentPrice;

    enum MarketTrend{BULL, BEAR} 
    MarketTrend public currentMarketTrend = MarketTrend.BULL; 
    
    string[] bullUrisIpfs = [
        "https://ipfs.io/ipfs/QmeSK7NqER1mpv4q1d4vgzURtGPXe4FQfBfoLwgdyp9mfT?filename=bull_1.json",
        "https://ipfs.io/ipfs/QmYmM3tvSPBAXrsQraud3mkPhAvAN1RPUZYK5PQNiVsM7N?filename=bull_2.json",
        "https://ipfs.io/ipfs/Qme6ANZheqJXU4igXxJ5LY2QNBY6QvGguuQ6qJi2B2evGy?filename=bull_3.json"
    ];
    string[] bearUrisIpfs = [
        "https://ipfs.io/ipfs/QmUGfc5DqhBMe4cVwHbc1u1fiXRQoRnfnkK1eQ4VLFMF8o?filename=bear_1.json",
        "https://ipfs.io/ipfs/QmNhm9RzYYD4FZ8HLb93ePHivAUjZNVUwJHbLjxya7ojDC?filename=bear_2.json",
        "https://ipfs.io/ipfs/QmP5yQSRSUCXNFagYraocA8YvmLN1HUUBSbhoUYJKUbTT3?filename=bear_3.json"
    ];

    event TokensUpdated(string marketTrend);

    // For testing with the mock on Goerli, pass in 10(seconds) for `updateInterval` and the address of your 
    // deployed  MockPriceFeed.sol contract.
    // BTC/USD Price Feed Contract Address on Goerli: 0xA39434A63A52E749F02807ae27335515BA4b07F7
    // Setup VRF. Goerli VRF Coordinator 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D

    constructor(uint updateInterval, address _pricefeed, address _vrfCoordinator) ERC721("MemeLott", "MLT") VRFConsumerBaseV2(_vrfCoordinator) {
        interval = updateInterval; 
        lastTimeStamp = block.timestamp;  

        pricefeed = AggregatorV3Interface(_pricefeed); 
        currentPrice = getLatestPrice();
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);  
    }

    function safeMint(address to) public  {
        uint256 tokenId = _tokenIdCounter.current();

        _tokenIdCounter.increment();

        _safeMint(to, tokenId);

        string memory defaultUri = bullUrisIpfs[2];
        _setTokenURI(tokenId, defaultUri);

        console.log("DONE!!! minted token ", tokenId, " and assigned token url: ", defaultUri);
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /*performData */) {
         upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata /* performData */ ) external override {
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;         
            int latestPrice =  getLatestPrice(); 
        
            if (latestPrice == currentPrice) {
                console.log("NO CHANGE -> returning!");
                return;
            }

            if (latestPrice < currentPrice) {
                // bear
                currentMarketTrend = MarketTrend.BEAR;
            } else {
                // bull
                currentMarketTrend = MarketTrend.BULL;
            }

            requestRandomnessForNFTUris();
            currentPrice = latestPrice;
        } else {
            console.log(
                " INTERVAL NOT UP!"
            );
            return;
        }
    }

    function getLatestPrice() public view returns (int256) {
         (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = pricefeed.latestRoundData();

        return price; 
    }

    function requestRandomnessForNFTUris() internal {
        require(s_subscriptionId != 0, "Subscription ID not set"); 

        s_requestId = COORDINATOR.requestRandomWords(
            keyhash,
            s_subscriptionId, 
            3, 
            callbackGasLimit,
            1 
        );

        console.log("Request ID: ", s_requestId);
    }

  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;

    console.log("...Fulfilling random Words");
    
    string[] memory urisForTrend = currentMarketTrend == MarketTrend.BULL ? bullUrisIpfs : bearUrisIpfs;
    uint256 idx = randomWords[0] % urisForTrend.length; 


    for (uint i = 0; i < _tokenIdCounter.current() ; i++) {
        _setTokenURI(i, urisForTrend[idx]);
    } 

    string memory trend = currentMarketTrend == MarketTrend.BULL ? "bullish" : "bearish";
    
    emit TokensUpdated(trend);
  }


  function setPriceFeed(address newFeed) public onlyOwner {
      pricefeed = AggregatorV3Interface(newFeed);
  }
  function setInterval(uint256 newInterval) public onlyOwner {
      interval = newInterval;
  }

  function setSubscriptionId(uint64 _id) public onlyOwner {
      s_subscriptionId = _id;
  }


  function setCallbackGasLimit(uint32 maxGas) public onlyOwner {
      callbackGasLimit = maxGas;
  }

  function setVrfCoodinator(address _address) public onlyOwner {
    COORDINATOR = VRFCoordinatorV2Interface(_address);
  }
    


    // Helpers
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function updateAllTokenUris(string memory trend) internal {
    }




    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}