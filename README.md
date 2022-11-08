# Metascreen

[Metascreen](https://metascreen.squirrelverse.io/) is a project by [Squirrel Verse LLC](https://squirrelverse.io/). The project is a curated NFT commerce platform for showcasing unique NFTs.

The smart contract in this repository is used to mint and trade the NFTs for this project. It is deployed in the polygon mainnet.

## Features
- Each NFT is unique and identified separately by token Id same as ERC721.
- Royalty is implemented for creator. The royalty cut can be changed by the contract owner after deploying the contract.
- Trading the NFT will charge extra as some part of the amount will be payed as royalty to creator.
- NFTs are burnable.

## Functions
- `safeMint(string uri)` : To mint a new NFT.
- `listToken(uint tokenId,  uint256 _price)` : To list your token in marketplace for resale after buying it.
- `delistToken(uint tokenId)` : If you change your mind regarding listing.
- `buytoken(uint256 tokenId)` : The first transfer after a NFT is minted is done using this function. This is a payable function.
- `trade(uint256 tokenId)` : The subsequent transfers after buying from one owner to next owner is done with this function. This is also payable with royalty implemented. No other function can be used to transfer except this.
- `getNFT(uint tokenId)` : to get the details about a cetain NFT.
