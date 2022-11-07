// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./EIP712MetaTransaction.sol";

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    constructor() {
        
        priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}



contract Movie is ERC721, ERC721URIStorage, Ownable, PriceConsumerV3, EIP712MetaTransaction("Movie","1") {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    address own;
    address public squirrel;
    address public creator;
    uint public listPrice;
    uint public royaltyCut;
    uint public tradingFee;
    uint public squirrelCommission;
    mapping(uint256 => address) public track;
    mapping(uint256 => bool) public listed;
    mapping(uint256 => uint256) public listedPrice;

    struct NFTinfo{
        uint256 tokenId;
        string uri;
        address owner;
        uint256 price;
        bool listingStatus;
    }

    constructor(address creator_initialize, address _sq) ERC721("Mithila Makhaan", "MMM") {
        require(_sq != address(0),"Enter addresses");
        require(creator_initialize != address(0),"Enter addresses");
        creator=creator_initialize;
        own=msg.sender;
        squirrel = _sq;
        royaltyCut = 20;
        listPrice = 12;
        tradingFee = 1;
        squirrelCommission = 50;
    }

    function safeMint(string memory uri) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        track[tokenId]=own;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);  
        listedPrice[tokenId] = listPrice;
    }

    function mint_batch(uint256 quantity,string[] memory uris) public onlyOwner
    {
        for(uint256 i=0;i < quantity; i++){
            safeMint(uris[i]);
        }
    }

    function updateURI(uint tokenId, string memory uri)public{
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner==msg.sender || own==msg.sender, "Only Contract/Token Owner can update URI");
        _setTokenURI(tokenId, uri);  
    }

    function listToken(uint tokenId,  uint256 _price)public{
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner==msg.sender, "Only Token Owner can list");
        require(_price >= listPrice, "Minimum price for listing is not met");
        listed[tokenId]= true; 
        listedPrice[tokenId] = _price;
    }

    function delistToken(uint tokenId)public{
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner==msg.sender, "Only Token Owner can delist");
        listed[tokenId]= false; 
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

    function buytoken(uint256 tokenId)public  payable {
       
        int price= getLatestPrice();
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner == own,  " Only for first tx");
        uint256 p = uint256(price);
        require(msg.value >= ((listedPrice[tokenId]*1e26)/p) ,"Payment amount is less than listed price");

        _transfer(own, msg.sender, tokenId);
        track[tokenId]= msg.sender;

        address payable _to1= payable(squirrel);
        address payable _to2= payable(creator);

        _to1.transfer(msg.value*squirrelCommission/1000);
        _to2.transfer((msg.value*(1000-squirrelCommission))/1000);

    }

    function trade(
        uint256 tokenId
    ) public payable {
        address payable tokenOwner = payable(ownerOf(tokenId));
        require(listed[tokenId]==true,"token is not listed");
        listed[tokenId]=false;
        
        int price= getLatestPrice();
        uint256 p = uint256(price);
        require(msg.value >= ((listedPrice[tokenId]*1e26)/p) ,"Trade Amount should be more than listing Price");
        
        track[tokenId]= msg.sender;
        _transfer(tokenOwner, msg.sender, tokenId);

        address payable _to2= payable(creator);
        _to2.transfer(msg.value*royaltyCut/1000);
        
        address payable _to3= payable(squirrel);
        _to3.transfer(msg.value*tradingFee/1000);

        tokenOwner.transfer(msg.value*(1000-royaltyCut-tradingFee)/1000);
    }

    function changeRoyaltyCut(uint _n) public onlyOwner{
        royaltyCut = _n;
    }

    function changeListPrice(uint _n) public onlyOwner{
        listPrice = _n;
    }

    function changeTradingFee(uint _n) public onlyOwner{
        tradingFee = _n;
    }

    function changeSquirrelCommission(uint _n) public onlyOwner{
        squirrelCommission = _n;
    }

    function changeCreator(address _n) public onlyOwner{
        require(_n != address(0),"Enter valid address");
        creator = _n;
    }
    
    function changeSquirrelWallet(address _n) public onlyOwner{
        require(_n != address(0),"Enter valid address");
        squirrel = _n;
    }

    function transferByOwner(
        address from,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        _transfer(from, to, tokenId);
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function getNFT(uint256 tokenId) public view returns(NFTinfo memory){
        NFTinfo memory temp = NFTinfo(tokenId, tokenURI(tokenId), ownerOf(tokenId), listedPrice[tokenId], listed[tokenId]);
        return temp;
    }

    function getNFT(uint256 startTokenId, uint256 endTokenId) public view returns(NFTinfo[] memory){
        
        uint256 size = endTokenId - startTokenId + 1;
        NFTinfo[] memory res = new NFTinfo[](size);

        uint256 k =0;
        for(uint256 i=startTokenId;i<=endTokenId;i++){
            NFTinfo memory temp = NFTinfo(i, tokenURI(i), ownerOf(i), listedPrice[i], listed[i]);
            res[k] = temp;
            k++;
        }

        return res;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data)public view override(ERC721) {
        require(msg.sender == own);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId)public view override(ERC721) {
        require(msg.sender == own);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId)public view override(ERC721) {
        require(msg.sender == own);
    }
}