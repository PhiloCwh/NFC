// SPDX-License-Identifier: MIT
//import "./lptoken.sol";
import "./ILPToken.sol";
//import "./IERC20.sol";
import "./lptoken.sol";
import "./IWETH.sol";
import "./IFragmentation.sol";
import "./ICalculate.sol";

pragma solidity ^0.8.17;

contract NFTAMM {
//全局变量


    uint constant ONE_ETH = 10 ** 18;
    mapping(address => address) pairCreator;//lpAddr pairCreator

    address [] public lpTokenAddressList;//lptoken的数组
    address [] public rewardTokenAddressList;

    mapping(address => mapping(address => uint)) reserve;//第一个address是lptoken的address ，第2个是相应token的资产，uint是资产的amount

    //检索lptoken
    mapping(address => mapping(address => address)) findLpToken;
    mapping(address => mapping(address => address)) findRewardToken;

    IWETH immutable WETH;
    IFragmentation immutable framentation;
    ICalculate immutable calculate;
    address immutable WETHAddr;
    address immutable fundContract;



    constructor(address _wethAddr, address _framentation, address _calculate,address _fundContract)
    {
        WETH = IWETH(_wethAddr);
        WETHAddr = _wethAddr;
        framentation = IFragmentation(_framentation);
        calculate = ICalculate(_calculate);
        fundContract = _fundContract;

    }

    receive() payable external {}

    modifier reEntrancyMutex() {
        bool _reEntrancyMutex;

        require(!_reEntrancyMutex,"FUCK");
        _reEntrancyMutex = true;
        _;
        _reEntrancyMutex = false;

    }

//业务合约
    //添加流动性

    function addLiquidityWithETH(address _token, uint _tokenAmount) public payable reEntrancyMutex
    {
        uint ETHAmount = msg.value;
        address user = msg.sender;
       // address addr = address(this);
        WETH.depositETH{value : ETHAmount}();
        //WETH.approve(user,ETHAmount);
        WETH.transfer(user,ETHAmount);
        addLiquidity(WETHAddr,_token, ETHAmount,_tokenAmount);
        

    }

    function addLiquidityWithFT(address _token0, address _token1, uint _amount0,uint _amount1) public 
    {

        //ILPToken lptoken;//lptoken接口，为了mint 和 burn lptoken

        address user = msg.sender;
        require(_amount0 > 0 ,"require _amount0 > 0 && _amount1 >0");
        require(framentation.isFTToken(_token0),"not FT token");
        require(_token0 != _token1, "_token0 == _token1");
        {
        IERC20 token0 = IERC20(_token0);
        token0.transferFrom(user, address(this), _amount0);
        }

        /*
        How much dx, dy to add?
        xy = k
        (x + dx)(y + dy) = k'
        No price change, before and after adding liquidity
        x / y = (x + dx) / (y + dy)
        x(y + dy) = y(x + dx)
        x * dy = y * dx
        x / y = dx / dy
        dy = y / x * dx
        */
        //问题：
        /*
        如果项目方撤出所有流动性后会存在问题
        1.添加流动性按照比例 0/0 会报错

        解决方案：
        每次添加至少n个token
        且remove流动性至少保留n给在amm里面

        */

        if (findLpToken[_token1][_token0] == address(0)) {

            IERC20 token1 = IERC20(_token1);
            token1.transferFrom(user, address(this), _amount1);


            //当lptoken = 0时，创建lptoken
            //shares = _sqrt(_amount0 * _amount1);


            //lptokenAddr = findLpToken[_token1][_token0];
            //rewardTokenAddr = findRewardToken[_token1][_token0];

            //lptoken = ILPToken(findLpToken[_token1][_token0]);//实例化为调用mint方法
            //rewardToken = ILPToken(findRewardToken[_token1][_token0]);
            _creatpairLogic(_token0,_token1,_amount0,_amount1,user);

            
        } else {
            _amount1 = reserve[findLpToken[_token1][_token0]][_token1] * _amount0 / reserve[findLpToken[_token1][_token0]][_token0];


            IERC20 token1 = IERC20(_token1);
            token1.transferFrom(user, address(this), _amount1);
            


            _pairCreatedLogic(_token0,_token1,_amount0,_amount1,user);


            //获取lptoken地址
        }
        //require(shares > 0, "shares = 0");

        //lptoken.mint(msg.sender,shares);
        
        

        _update(findLpToken[_token1][_token0],_token0, _token1, reserve[findLpToken[_token1][_token0]][_token0] + _amount0, reserve[findLpToken[_token1][_token0]][_token1] + _amount1);
    }

    function _creatpairLogic(address _token0, address _token1, uint _amount0,uint _amount1, address _user) internal
    {

            uint shares = _sqrt(_amount0 * _amount1);

            ILPToken rewardToken;
            ILPToken lptoken;

            lptoken = ILPToken(createPair(_token0,_token1));
            rewardToken = ILPToken(createRewardToken(_token0,_token1));

            //lptokenAddr = findLpToken[_token1][_token0];
            //rewardTokenAddr = findRewardToken[_token1][_token0];

            //lptoken = ILPToken(findLpToken[_token1][_token0]);//实例化为调用mint方法
            //rewardToken = ILPToken(findRewardToken[_token1][_token0]);

            pairCreator[findLpToken[_token1][_token0]] = msg.sender;//保留最后的流动性

            lptoken.mint(_user,shares);
            rewardToken.mint(msg.sender, calculate.calculateRewardTokenAmount(0,_amount0));
            
        
    }

    function _pairCreatedLogic(address _token0, address _token1, uint _amount0, uint _amount1, address _user) internal 
    {
            ILPToken rewardToken;
            ILPToken lptoken;
            //获取lptoken地址
            address lptokenAddr = findLpToken[_token1][_token0];

            uint shares = _min(
                (_amount0 * lptoken.totalSupply()) / reserve[lptokenAddr][_token0],
                (_amount1 * lptoken.totalSupply()) / reserve[lptokenAddr][_token1]
            );
            //lptoken = ILPToken(lptokenAddr);//获取lptoken地址
            rewardToken = ILPToken(findRewardToken[_token1][_token0]);
            lptoken = ILPToken(lptokenAddr);

            lptoken.mint(_user,shares);
            rewardToken.mint(_user,calculate.calculateRewardTokenAmount(reserve[lptokenAddr][_token0],_amount0));
            //获取lptoken地址
    }

    function addLiquidity(address _token0, address _token1, uint _amount0,uint _amount1) public returns (uint shares) {
        
        ILPToken lptoken;//lptoken接口，为了mint 和 burn lptoken
        
        require(_amount0 > 0 ,"require _amount0 > 0 && _amount1 >0");
        require(_token0 != _token1, "_token0 == _token1");
        IERC20 token0 = IERC20(_token0);
        token0.transferFrom(msg.sender, address(this), _amount0);
        address lptokenAddr;

        /*
        How much dx, dy to add?
        xy = k
        (x + dx)(y + dy) = k'
        No price change, before and after adding liquidity
        x / y = (x + dx) / (y + dy)
        x(y + dy) = y(x + dx)
        x * dy = y * dx
        x / y = dx / dy
        dy = y / x * dx
        */
        //问题：
        /*
        如果项目方撤出所有流动性后会存在问题
        1.添加流动性按照比例 0/0 会报错

        解决方案：
        每次添加至少n个token
        且remove流动性至少保留n给在amm里面

        */
        if (findLpToken[_token1][_token0] != address(0)) {
            lptokenAddr = findLpToken[_token1][_token0];
            _amount1 = reserve[lptokenAddr][_token1] * _amount0 / reserve[lptokenAddr][_token0];
            IERC20 token1 = IERC20(_token1);
            token1.transferFrom(msg.sender, address(this), _amount1);
            //require(reserve0[lptokenAddr][_token0] * _amount1 == reserve1[lptokenAddr][_token1] * _amount0, "x / y != dx / dy");
            //必须保持等比例添加，添加后k值会改变
        }

        if (findLpToken[_token1][_token0] == address(0)) {
            //当lptoken = 0时，创建lptoken
            shares = _sqrt(_amount0 * _amount1);
            createPair(_token0,_token1);
            lptokenAddr = findLpToken[_token1][_token0];
            lptoken = ILPToken(lptokenAddr);//获取lptoken地址
            pairCreator[lptokenAddr] = msg.sender;
            IERC20 token1 = IERC20(_token1);
            token1.transferFrom(msg.sender, address(this), _amount1);
            
        } else {
            lptoken = ILPToken(lptokenAddr);//获取lptoken地址
            shares = _min(
                (_amount0 * lptoken.totalSupply()) / reserve[lptokenAddr][_token0],
                (_amount1 * lptoken.totalSupply()) / reserve[lptokenAddr][_token1]
            );
            //获取lptoken地址
        }
        require(shares > 0, "shares = 0");
        lptoken.mint(msg.sender,shares);
        

        _update(lptokenAddr,_token0, _token1, reserve[lptokenAddr][_token0] + _amount0, reserve[lptokenAddr][_token1] + _amount1);
    }
    //移除流动性

    function removeLiquidity(
        address _token0,
        address _token1,
        uint _shares
    ) external returns (uint amount0, uint amount1) {
        ILPToken lptoken;//lptoken接口，为了mint 和 burn lptoken
        IERC20 token0 = IERC20(_token0);
        IERC20 token1 = IERC20(_token1);
        address lptokenAddr = findLpToken[_token0][_token1];

        lptoken = ILPToken(lptokenAddr);

        if(pairCreator[lptokenAddr] == msg.sender)
        {
            require(lptoken.balanceOf(msg.sender) - _shares > 100 ,"paieCreator should left 100 wei lptoken in pool");
        }

        amount0 = (_shares * reserve[lptokenAddr][_token0]) / lptoken.totalSupply();//share * totalsuply/bal0
        amount1 = (_shares * reserve[lptokenAddr][_token1]) / lptoken.totalSupply();
        require(amount0 > 0 && amount1 > 0, "amount0 or amount1 = 0");

        lptoken.burn(msg.sender, _shares);
        _update(lptokenAddr,_token0, _token1, reserve[lptokenAddr][_token0] - amount0, reserve[lptokenAddr][_token1] - amount1);
        

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
    }

    //交易

    function swapWithETH(address _tokenOut,uint _disirSli) public payable reEntrancyMutex
    {
        uint amountIn = msg.value;
        WETH.depositETH{value : amountIn}();
        swapByLimitSli(WETHAddr,_tokenOut,amountIn, _disirSli);
    }


    function swapToETH(address _tokenIn, uint _amountIn, uint _disirSli)public {
        uint amountOut = swapByLimitSli(_tokenIn,WETHAddr,_amountIn, _disirSli);
        WETH.withdrawETH(amountOut);
        address payable user = payable(msg.sender);
        user.transfer(amountOut);

    }


    function swap(address _tokenIn, address _tokenOut, uint _amountIn) public returns (uint amountOut) {
        require(
            findLpToken[_tokenIn][_tokenOut] != address(0),
            "invalid token"
        );
        require(_amountIn > 0, "amount in = 0");
        require(_tokenIn != _tokenOut);
        require(_amountIn >= 1000, "require amountIn >= 0.0001 ethers token");

        IERC20 tokenIn = IERC20(_tokenIn);
        IERC20 tokenOut = IERC20(_tokenOut);
        address lptokenAddr = findLpToken[_tokenIn][_tokenOut];
        uint reserveIn = reserve[lptokenAddr][_tokenIn];
        uint reserveOut = reserve[lptokenAddr][_tokenOut];

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);



        /*
        How much dy for dx?
        xy = k
        (交易后)(x + dx)(y - dy) = k 对于交易所的视角 k = xy(交易前) y -dy = xy/(x + dx) // dy = y - xy/(x + dx)
        y - dy = k / (x + dx)           // = (y(x + dx)  - xy) / (x + dx) = ydx  / (x + dx)
        y - k / (x + dx) = dy
        y - xy / (x + dx) = dy
        (yx + ydx - xy) / (x + dx) = dy
        ydx / (x + dx) = dy
        */
        // 0.5% fee
        uint amountInWithFee = (_amountIn * 995) / 1000;

        tokenIn.transfer(fundContract,(_amountIn * 3) / 1000);

        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);

        //(输出的token总数量 * 输入的token数量) / (输入token的总数量 + 输入的token数量)
        // 比如有1000输出token，200输入token，用户输入50token，
        //则 (1000 * 50)/(200 + 50) = 200 
        //原价1000 ：200 是 5 ：1
        //输出对比是 200 ：50 是 4 ：1
        //出现这个结果就是滑点问题

        /*
        比如100000token1，20000token0，用户输入50token0
        则(100000 * 50) / (20000 + 50) = 249.376558603
        原价1000 ：200 是 5 ：1
        输出对比是 249.376558603 ：50 是接近 5 ：1
        池子越大用户的购买的比例占池子比例越低，则滑点越低
        */

        tokenOut.transfer(msg.sender, amountOut);
        uint totalReserve0 = reserve[lptokenAddr][_tokenIn] + amountInWithFee; 
        uint totalReserve1 = reserve[lptokenAddr][_tokenOut] - amountOut;

        _update(lptokenAddr,_tokenIn, _tokenOut, totalReserve0, totalReserve1);
    }
    //交易携带滑点限制
    function swapByLimitSli(address _tokenIn, address _tokenOut, uint _amountIn, uint _disirSli) public returns(uint amountOut){
        require(
            findLpToken[_tokenIn][_tokenOut] != address(0),
            "invalid token"
        );
        require(_amountIn > 0, "amount in = 0");
        require(_tokenIn != _tokenOut);
        require(_amountIn >= 1000, "require amountIn >= 1000 wei token");

        IERC20 tokenIn = IERC20(_tokenIn);
        IERC20 tokenOut = IERC20(_tokenOut);
        address lptokenAddr = findLpToken[_tokenIn][_tokenOut];
        uint reserveIn = reserve[lptokenAddr][_tokenIn];
        uint reserveOut = reserve[lptokenAddr][_tokenOut];

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);



        uint amountInWithFee = (_amountIn * 997) / 1000;
        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);

        //检查滑点
        setSli(amountInWithFee,reserveIn,reserveOut,_disirSli);


        tokenOut.transfer(msg.sender, amountOut);
        uint totalReserve0 = reserve[lptokenAddr][_tokenIn] + _amountIn; 
        uint totalReserve1 = reserve[lptokenAddr][_tokenOut] - amountOut;

        _update(lptokenAddr,_tokenIn, _tokenOut, totalReserve0, totalReserve1);

    }

    //暴露数据查询方法

    function getReserve(address _lpTokenAddr, address _tokenAddr) public view returns(uint)
    {
        return reserve[_lpTokenAddr][_tokenAddr];
    }

    function getLptoken(address _tokenA, address _tokenB) public view returns(address)
    {
        return findLpToken[_tokenA][_tokenB];
    }

    function getRewardtoken(address _tokenA, address _tokenB) public view returns(address)
    {
        return findRewardToken[_tokenA][_tokenB];
    }


    function lptokenTotalSupply(address _token0, address _token1, address user) public view returns(uint)
    {
        ILPToken lptoken;
        lptoken = ILPToken(findLpToken[_token0][_token1]);
        uint totalSupply = lptoken.balanceOf(user);
        return totalSupply;
    }

    function getLptokenLength() public view returns(uint)
    {
        return lpTokenAddressList.length;
    }

//依赖方法
    //creatpair

    function createPair(address addrToken0, address addrToken1) internal returns(address){
        bytes32 _salt = keccak256(
            abi.encodePacked(
                addrToken0,addrToken1
            )
        );
        new LPToken{
            salt : bytes32(_salt)
        }
        ();
        address lptokenAddr = getAddress(getBytecode(),_salt);

         //检索lptoken
        lpTokenAddressList.push(lptokenAddr);
        findLpToken[addrToken0][addrToken1] = lptokenAddr;
        findLpToken[addrToken1][addrToken0] = lptokenAddr;

        return lptokenAddr;
    }

    function createRewardToken(address addrToken0, address addrToken1) internal returns(address){
        bytes32 _salt = keccak256(
            abi.encodePacked(
                "RewardToken",
                addrToken0,addrToken1
            )
        );
        new LPToken{
            salt : bytes32(_salt)
        }
        ();
        address rewardTokenAddr = getAddress(getBytecode(),_salt);

         //检索lptoken
        rewardTokenAddressList.push(rewardTokenAddr);
        findRewardToken[addrToken0][addrToken1] = rewardTokenAddr;
        findRewardToken[addrToken1][addrToken0] = rewardTokenAddr;

        return rewardTokenAddr;
    }

    function getBytecode() internal pure returns(bytes memory) {
        bytes memory bytecode = type(LPToken).creationCode;
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

    //数据更新

    function _update(address lptokenAddr,address _token0, address _token1, uint _reserve0, uint _reserve1) private {
        reserve[lptokenAddr][_token0] = _reserve0;
        reserve[lptokenAddr][_token1] = _reserve1;
    }

//数学库

    function _sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function setSli(uint dx, uint x, uint y, uint _disirSli) private pure returns(uint){


        uint amountOut = (y * dx) / (x + dx);

        uint dy = dx * y/x;
        /*
        loseAmount = Idea - ammOut
        Sli = loseAmount/Idea
        Sli = [dx*y/x - y*dx/(dx + x)]/dx*y/x
        */
        uint loseAmount = dy - amountOut;

        uint Sli = loseAmount * 10000 /dy;
        
        require(Sli <= _disirSli, "Sli too large");
        return Sli;

    }



}
