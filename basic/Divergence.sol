/*
    智能合约解决方案
    需求：
        剪刀石头布可能有人先出手，有人后出手
        数据说明：
            0 - 剪刀
            1 - 石头
            2 - 布
        使用library： 获胜的计算方式
        interface
            玩家注册
            2个玩家
*/

pragma solidity^0.8.7;
// SPDX-License-Identifier: UNLICENSED

// 定义接口

interface IDivergence {
    // 注册
    function register(string memory _name) external;
    // 出手
    function choose(uint8 _opt) external;
    // 查看获胜
        // 返回值 1. 昵称 2. 玩家1出手 3. 玩家2出手 4. 轮次
    function winner() external view returns (string memory, uint8, uint8, uint256);
}

// 定义library
library Math {
    // 玩家1 & 玩家2
    //   返回值  0 相等  
    //          1 大于 
    //          2 小于
    function winner(uint8 a, uint8 b) internal  pure returns (uint8) {
        require(a <= 2);
        require(b <= 2);
        if( a == b) {
            return 0;
        } else if (a > b) {
            // a 1 b 0 石头 > 剪刀
            // a 2 b 1 布 > 石头
            // a 2 b 0 布 < 剪刀
            return a - b;
        } else {
            // a 0 b 1
            // a 1 b 2
            // a 0 b 2
            if (b - a == 2) return 1; // 返回1说明 a > b 即 剪刀 > 石头
            if (b - a == 1) return 2; // a < b 
        } 
        return 0;
    }
}

// 玩家信息
struct Player {
    address user;
    string name;
    uint8 opt; // 出手选项 0，1，2
    uint256 round; // 出手轮次
}

// 合约实现
contract Divergence is IDivergence {

    // 控制玩家数量
    uint8 userCount;
    // 记录玩家信息  应该用mapping存储
    Player[2] playerList;
    // 游戏是否结束
    bool isFinished; // default false

    // 记录谁赢了
    uint8 winnerIndex;

    event WinnerLog(address indexed addr, uint8 opt, uint8 returnVal);

    // 注册
    function register(string memory _name) override  external {
        require(userCount <=2, "two player only" );

        for (uint i = 0; i < playerList.length; i++) {
            require(keccak256(abi.encodePacked(playerList[i].name)) != 
                    keccak256(abi.encodePacked(_name)), 
                    string.concat(_name, " player already register"));
        }
        
        playerList[userCount].user = msg.sender;
        playerList[userCount].name = _name;
        userCount ++;
    }
    // 出手 先手直接出，后手要判断对方出什么，决定游戏是否结束
    function choose(uint8 _opt) override external {
        // 玩家身份
        require(isPlayer(msg.sender), "only register player can do");
        // 游戏是否结束
        require(!isFinished, "game finished");
        // 区分玩家1 和玩家2
        uint8 index1; // 本人
        uint8 index2; // 对手
        if (playerList[0].user == msg.sender) {
            index1 = 0;
            index2 = 1;
        } else {
            index1 = 1;
            index2 = 0;
        }
        Player storage player = playerList[index1];
        // 判断对方是否出手
        require(player.round <= playerList[index2].round, "please wait");
        player.opt = _opt;
        player.round ++;
        // 处理胜负逻辑
        if (player.round == playerList[index2].round) {
            uint8 win = Math.winner(player.opt, playerList[index2].opt);
            if (win == 1) {
                isFinished = true;
                winnerIndex = index1;
            } else if (win == 2) {
                isFinished = true;
                winnerIndex = index2;
            }
            emit WinnerLog(msg.sender, _opt, win);
        }
    }
    // 查看获胜
        // 返回值 1. 昵称 2. 玩家1出手 3. 玩家2出手 4. 轮次
    function winner() override external view returns (string memory, uint8, uint8, uint256) {
        if (!isFinished) {
            return ("", 255, 255, 666666);
        }

        uint8 lossIndex = 0; // 输的一方索引
        if(winnerIndex == 0) lossIndex = 1;

        return (
            playerList[winnerIndex].name,
            playerList[winnerIndex].opt,
            playerList[lossIndex].opt,
            playerList[winnerIndex].round
        );
    }

    // 判断是否是注册玩家
    function isPlayer(address _addr) public view returns (bool) {

        if (_addr == playerList[0].user || _addr == playerList[1].user) 
            return true;
        return false;
    }

}