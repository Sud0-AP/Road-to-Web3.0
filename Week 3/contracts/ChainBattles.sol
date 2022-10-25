// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract ChainBattles is ERC721URIStorage {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct warrior{
        uint256 level;
        uint256 speed;
        uint256 strength;
        uint256 life;
    }

    mapping(uint256 => warrior) public tokenIdToData;

    constructor() ERC721("Chain Battles", "CBTLS") {}

    function generateCharacter(uint256 tokenId) public returns (string memory) {
        bytes memory svg = abi.encodePacked(
             '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
            "<style>.base { fill: red; font-family: Verdana, sans-serif; font-size: 40px; }</style>",
            "<style>.sub { fill: white; font-family: 'Courier New', monospace; font-size: 14px; }</style>",
            '<rect width="100%" height="100%" fill="black" />',
            
            '<text x="50%" y="25%" class="base" dominant-baseline="middle" text-anchor="middle">',
            "Warrior",
            "</text>",
            '<text x="50%" y="40%" class="sub" dominant-baseline="middle" text-anchor="middle">',
            "Levels : ", 
            getLevels(tokenId),
            "</text>",
            '<text x="50%" y="50%" class="sub" dominant-baseline="middle" text-anchor="middle">',
            "Speed : ",
            getSpeed(tokenId),
            "</text>",
            '<text x="50%" y="60%" class="sub" dominant-baseline="middle" text-anchor="middle">',
            "Strength : ",
            getStrength(tokenId),
            "</text>",
            '<text x="50%" y="70%" class="sub" dominant-baseline="middle" text-anchor="middle">',
            "Life : ",
            getLife(tokenId),    
            "</text>"
            "</svg>"
        );
        return string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svg)
                )
            );
    }

    function getSpeed(uint256 tokenId) public view returns (string memory) {
        uint256 speed = tokenIdToData[tokenId].speed;
        return speed.toString();
    }

    function getLevels(uint256 tokenId) public view returns (string memory) {
        uint256 levels = tokenIdToData[tokenId].level;
        return levels.toString();
    }

    function getLife(uint256 tokenId) public view returns (string memory) {
        uint256 levels = tokenIdToData[tokenId].life;
        return levels.toString();
    }
    function getStrength(uint256 tokenId) public view returns (string memory) {
        uint256 levels = tokenIdToData[tokenId].strength;
        return levels.toString();
    }



    function getTokenURI(uint256 tokenId) public returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Chain Battles #',
            tokenId.toString(),
            '",',
            '"description": "Battles on chain",',
            '"image": "',
            generateCharacter(tokenId),
            '"',
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function mint() public {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        tokenIdToData[newItemId].level = 0; //set the initial level to 0
        tokenIdToData[newItemId].speed=10;//set the initial speed to 10
        tokenIdToData[newItemId].strength=10;//set the initial strength to 10
        tokenIdToData[newItemId].life=10;//set the initial life to 10
        _setTokenURI(newItemId, getTokenURI(newItemId));
    }

    function train(uint256 tokenId) public {
        require(_exists(tokenId), "Please use an existing token");
        require(ownerOf(tokenId) == msg.sender, "You must own this token to train it");
        
        uint256 currentLevel = tokenIdToData[tokenId].level;
        uint256 currentSpeed = tokenIdToData[tokenId].speed;
        uint256 currentStrength = tokenIdToData[tokenId].strength;
        uint256 currentLife = tokenIdToData[tokenId].life;

        tokenIdToData[tokenId].level = currentLevel + 1; 
        //incriment randomly 
        tokenIdToData[tokenId].speed = currentSpeed + uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % (30*tokenId); 
        tokenIdToData[tokenId].strength = currentStrength + uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % (50*tokenId); 
        tokenIdToData[tokenId].life = currentLife + uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % (5*tokenId); 

        _setTokenURI(tokenId, getTokenURI(tokenId));
    }
}
