// SPDX-License-Identifier: MIT

import "./FT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

pragma solidity ^0.8.17;

contract Fragmentation{

    uint constant ONE_ETH = 10 ** 18;
    mapping(address =>mapping(address => mapping(uint => bool))) public nft_StakeIndex;//useraddress nftaddress tokenid

    mapping(address => bool) public isFTCreated;//相关系列的nft是否被create
    
    address [] public FTAddressList;
    mapping(address => address) public findFT;
    mapping(address => bool) public isFTToken;


    //碎片化NFT
    function tearApartNFT(address _nftAddr, uint _tokenId) public {
        IERC721 erc721 = IERC721(_nftAddr);
        FT ft;
        address user = msg.sender;
        require((erc721.getApproved(_tokenId) == address(this)) || (erc721.isApprovedForAll(user, address(this))),"not approve");
        require(erc721.ownerOf(_tokenId) == user, "not owner");
        erc721.transferFrom(user,address(this),_tokenId);
        uint FTAmount = 1000 * ONE_ETH;
        if (!isFTCreated[_nftAddr]) {
            //当lptoken = 0时，创建lptoken
            address ftAddr = createFT(_nftAddr);
            ft = FT(ftAddr);
            nft_StakeIndex[user][_nftAddr][_tokenId] = true;
            ft.mint(user,FTAmount);   
            isFTCreated[_nftAddr] = true;
            isFTToken[ftAddr] = true;
        }else
        {
            ft = FT(findFT[_nftAddr]);
            nft_StakeIndex[user][_nftAddr][_tokenId] = true;
            ft.mint(user,FTAmount); 
        }

        
    }

    function recoverNFT(address _nftAddr,uint _tokenId) public {

        address user = msg.sender;
        require(nft_StakeIndex[user][_nftAddr][_tokenId],"not NFT here");
        FT ft = FT(findFT[_nftAddr]);
        //require(ft.balanceOf(user) >= 1000 * ONE_ETH, "NO enought FT");
        ft.burn(user, 1000 * ONE_ETH);
        IERC721 erc721 = IERC721(_nftAddr);
        erc721.transferFrom(address(this),user,_tokenId);
        nft_StakeIndex[user][_nftAddr][_tokenId] = false;
        


    }

    function getFTAddr(address _nftAddr) public view returns(address FTAddr)
    {
        return findFT[_nftAddr];
    }

    function getFTLength() public view returns(uint Length)
    {
        return FTAddressList.length;
    }

    function createFT(address _nftAddr) internal returns(address){
        bytes32 _salt = keccak256(
            abi.encodePacked(
                _nftAddr
            )
        );
        new FT{
            salt : bytes32(_salt)
        }
        ();
        address FTAddr = getAddress(getFTBytecode(),_salt);

         //检索lptoken
        FTAddressList.push(FTAddr);
        //isFTCreated[FTAddr] = true;
        findFT[_nftAddr] = FTAddr;
        //findLpToken[addrToken0][addrToken1] = lptokenAddr;

        return FTAddr;
    }

    function getFTBytecode() internal pure returns(bytes memory) {
        bytes memory bytecode = type(FT).creationCode;
        return bytecode;
    }

    function getAddress(bytes memory bytecode, bytes32 _salt)
        internal
        view
        returns(address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), _salt, keccak256(bytecode)
            )
        );

        return address(uint160(uint(hash)));
    }


}
