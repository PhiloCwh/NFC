//https://eth-sepolia.g.alchemy.com/v2/oe_H-jFeP3dahloZpd7xS_TiNdTo7lCuimport { ethers } from "ethers";
import { ethers } from "ethers";
//准备 alchemy API 可以参考https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Tools/TOOL04_Alchemy/readme.md 
const SEPOLIA = 'https://eth-sepolia.g.alchemy.com/v2/oe_H-jFeP3dahloZpd7xS_TiNdTo7lCu';
const provider = new ethers.providers.JsonRpcProvider(SEPOLIA);
const privateKey = '0xc2ecb7953b8807a6ef408af0cec50dd2b00d48b48b0d2500e09296c0333f2c55'
const signer = new ethers.Wallet(privateKey, provider)

// 合约abi
const abiData = [
    "function getTokenPrice(address _tokenA, address _tokenB) public view returns(uint reserveA,uint reserveB, uint one_tokenA_price,uint one_tokenB_price)",
];
const abiNFC = [
    "function addLiquidityWithFT(address _token0, address _token1, uint _amount0,uint _amount1) public ",
    "function swap(address _tokenIn, address _tokenOut, uint _amountIn) public returns (uint amountOut)"
];
const addressData = "0xaB93Bc74E8aA9d291CE9F7637741c0d7C65D08c1"
const addressNFC = "0x2F912de2719BF405793EC19aC51f2eEA0C1CA27F"
const contractData = new ethers.Contract(addressData, abiData, provider)
const nfc = new ethers.Contract(addressNFC,abiNFC,signer)

const main = async () => {

    const price = await contractData.getTokenPrice("0xe18a08D672CbC977074a86D50427cb1B6276eAA7","0x511D92d9b8DD40f02Aa4A8e030b5A9a61523D616")
    console.log('----------{ 查看token储备量 }----------')
    console.log(`第一个为token1的储备量，第二个为token2的储备量 \n ${price}\n`)
    console.log('----------{ 添加流动性之后 }----------\n 添加token1 3000')
    await nfc.addLiquidityWithFT("0xe18a08D672CbC977074a86D50427cb1B6276eAA7","0x511D92d9b8DD40f02Aa4A8e030b5A9a61523D616",2500,10000)
    const price2 = await contractData.getTokenPrice("0xe18a08D672CbC977074a86D50427cb1B6276eAA7","0x511D92d9b8DD40f02Aa4A8e030b5A9a61523D616")

    console.log('----------{ 查看token储备量 }----------')
    console.log(`第一个为token1的储备量，第二个为token2的储备量 \n ${price2}\n`)
    
  }
  main()


