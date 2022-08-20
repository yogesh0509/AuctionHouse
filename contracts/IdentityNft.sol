// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract IdentityNft is ERC721{

    uint256 private s_tokenCounter;
    string private s_tokenUri;

    event nftminted(uint256 indexed tokenId);

    constructor(string memory tokenUri) ERC721("Player Identity Card", "PIC"){
        s_tokenCounter = 0;
        s_tokenUri = tokenUri;
    }

    function mintNft(address player) public{
        _safeMint(player, s_tokenCounter);
        emit nftminted(s_tokenCounter);
        s_tokenCounter += 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return s_tokenUri;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
    
}