/*
```_____````````````_````_`````````````````_``````````````_````````````
``/`____|``````````|`|``|`|```````````````|`|````````````|`|```````````
`|`|`````___```___`|`|`_|`|__```___```___`|`|`__```````__|`|`_____```__
`|`|````/`_`\`/`_`\|`|/`/`'_`\`/`_`\`/`_`\|`|/`/``````/`_``|/`_`\`\`/`/
`|`|___|`(_)`|`(_)`|```<|`|_)`|`(_)`|`(_)`|```<```_``|`(_|`|``__/\`V`/`
``\_____\___/`\___/|_|\_\_.__/`\___/`\___/|_|\_\`(_)``\__,_|\___|`\_/``
```````````````````````````````````````````````````````````````````````
```````````````````````````````````````````````````````````````````````
*/

// -> Cookbook is a free smart contract marketplace. Find, deploy and contribute audited smart contracts.
// -> Follow Cookbook on Twitter: https://twitter.com/cookbook_dev
// -> Join Cookbook on Discord:https://discord.gg/WzsfPcfHrk

// -> Find this contract on Cookbook: https://www.cookbook.dev/contracts/ETF-DAO/?utm=code



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";

contract Fund is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;

    struct Asset {
        address token;
        uint256 amount;
    }

    Asset[] public assets;

    constructor(
        string memory _name,
        string memory _symbol,
        address _router,
        address[] memory tokens,
        uint256[] memory amounts
    ) ERC20(_name, _symbol) {
        uniswapV2Router = IUniswapV2Router02(_router);
        // Don't think you can pass in structs as arg
        for (uint256 i = 0; i < tokens.length; i++) {
            assets.push(Asset(tokens[i], amounts[i]));
        }
    }

    function join(uint256 qty) external payable {
        for (uint256 i = 0; i < assets.length; i++) {
            Asset memory _asset = assets[i];

            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = _asset.token;

            uint256 desired = qty * _asset.amount;

            uniswapV2Router.swapETHForExactTokens{value: address(this).balance}(
                desired,
                path,
                address(this),
                block.timestamp
            ); // add swapped eth to eth variable
        }
        Address.sendValue(payable(msg.sender), address(this).balance);
        _mint(msg.sender, qty);
    }

    // Calculate tokens based on exit. Call swapExactTokensForETH
    function exit(uint256 qty) external {
        _burn(msg.sender, qty);

        for (uint256 i = 0; i < assets.length; i++) {
            Asset memory _asset = assets[i];

            address[] memory path = new address[](2);
            path[0] = _asset.token;
            path[1] = uniswapV2Router.WETH();

            uint256 desired = qty * _asset.amount;

            IERC20(_asset.token).approve(address(uniswapV2Router), desired);

            uniswapV2Router.swapExactTokensForETH(
                desired,
                0, // accept any amount of ETH
                path,
                msg.sender,
                block.timestamp
            );
        }
    }

    receive() external payable {}
}
