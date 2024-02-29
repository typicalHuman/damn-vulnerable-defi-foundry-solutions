# Damn Vulnerable Defi Solutions (Foundry)

Just my solutions for these challenges https://www.damnvulnerabledefi.xyz/. Foundry template - https://github.com/nicolasgarcia214/damn-vulnerable-defi-foundry.

# Checklist

- [x] 1 Unstoppable
- [x] 2 Naive receiver
- [x] 3 Truster
- [x] 4 Side Entrance
- [x] 5 The Rewarder
- [x] 6 Selfie
- [x] 7 Compromised
- [x] 8 Puppet
- [x] 9 Puppet V2
- [x] 10 Free Rider
- [x] 11 Backdoor
- [x] 12 Climber

# Explanations

## [1. Unstoppable](./unstoppable/)

### Context

UnstoppableLender's function `flashLoan` checks balance via storage variable and comparing it to the actual balance of the contract using token's `balanceOf` function.

### Hack

Simply send tokens so that the actual token balance of the contract is not equal to the value of the `poolBalance` variable.
![Scheme](./assets/1.%20Unstoppable.png)

---

## [2. Naive receiver](./naive-receiver/)

### Context

We have flashloan contract with the `FEE` of 1 ETH - `NaiveReceiverLanderPool`. And we have contract that could take flashloans from this contract and it should repay this huge fee after every flashloan - `FlashLoanReceiver`.

### Hack

Call flashloan until `FlashLoanReceiver` isn't drained, because it has a balance of 10 ETH and the fee is 1 ETH - you should call it 10 times until the contract isn't drained.
![Scheme](./assets/2.%20Naive%20Receiver.png)

---

## [3. Truster](./truster/)

### Context

We have flashloan contract that can execute any function name and parameters for the user of the contract. (It is much more convenient for the user to pass his own logic than to use an already prepared function that he has to implement, right?😉)

### Hack

Just encode approve data of the DVT token to our attacker's address and drain all value from the contract.

![Scheme](./assets/3.%20Truster.png)

---

## [4. Side Entrance](./side-entrance/)

### Context

Flashloan checks repayment via `balanceOf` and also it has deposit/withdraw functionality, what could go wrong?

### Hack

You should create custom contract for this one, the hack consists of these steps:

1. call `flashloan` from the attack contract
2. in `execute` flashloan payment handler (in the Attack contract) do a `deposit` of these funds
3. `SideEntryLenderPool` will check the balance of the contract and everything would be fine as the balance would be the same as it was before the flashloan.
4. call `withdraw` and get flashloaned funds back (and then send them to the attacker)
   ![Scheme](./assets/4.%20Side%20Entrance.png)

---

## [5. The Rewarder](./the-rewarder/)

### Context

We have rewarder contract that will distribute you some tokens every time you make a deposit to the contract.

### Hack

1. Flashloan huge amount of tokens
2. Receive the tokens
3. Deposit tokens and receive rewards from this huge deposit
4. Withdraw tokens back and repay flashloan.
   You got rewards for free, using just flashloan money.
   ![Scheme](./assets/5.%20The%20Rewarder.png)

---

## [6. Selfie](./selfie/)

### Context

We have pool and governance contract that allows voters to schedule some actions on the pool. Also the pool gives flashloan of the governance token and there are no fees.

### Hack

Take the flashloan of the governance token and schedule a `drainAllFunds` function, then send all the tokens back. You can do this because you became the largest voter in the governance contract at the time of the flashloan.
![Scheme](./assets/6.%20Selfie.png)

---

## [7. Compromised](./compromised/)

### Context

There are 3 trusted reporters that can update the oracle price. There's strange Cloudflare response and it seems like it's encoded utf-8 in base64 format.

### Hack

these bytes are private keys of 2 of the source. in order to get them you need:

1. convert bytes to utf-8:

```
4d 48 68 6a 4e 6a 63 34 5a 57 59 78 59 57 45 30 4e 54 5a 6b 59 54 59 31 59 7a 5a 6d 59 7a 55 34 4e 6a 46 6b 4e 44 51 34 4f 54 4a 6a 5a 47 5a 68 59 7a 42 6a 4e 6d 4d 34 59 7a 49 31 4e 6a 42 69 5a 6a 42 6a 4f 57 5a 69 59 32 52 68 5a 54 4a 6d 4e 44 63 7a 4e 57 45 35
```

for this one it would be:

```
MHhjNjc4ZWYxYWE0NTZkYTY1YzZmYzU4NjFkNDQ4OTJjZGZhYzBjNmM4YzI1NjBiZjBjOWZiY2RhZTJmNDczNWE5
```

this is base64 format

2. convert base64 to utf-8: 0xc678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9
   this is a private key for this address: 0xe92401A4d3af5E446d93D11EEc806b1462b39D15

repeat:

`MHgyMDgyNDJjNDBhY2RmYTllZDg4OWU2ODVjMjM1NDdhY2JlZDliZWZjNjAzNzFlOTg3NWZiY2Q3MzYzNDBiYjQ4`

0x208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48 - 0x81A5D6E50C214044bE44cA0CB057fe119097850c

Now you have private keys of 2/3 reporters in the network, so you can manipulate the price, using their private keys:
![Scheme](./assets/7.%20Compromised.png)

---

## [8. Puppet](./puppet/)

### Context

We have Uniswap V1 pool with small amounts of tokens in it and therefore the pool is very volatile.

### Hack

Because TVL is small, we can manipulate the price of the tokens within it and make one asset worth much more than another.
![Scheme](./assets/8.%20Puppet.png)

---

## [9. PuppetV2](./puppet-v2/)

### Context

The same as in PupperV1, but it uses UniswapV2 version.

### Hack

The same as in PuppetV1 works for PuppetV2, but the values are more limited.
![Scheme](./assets/8.%20Puppet.png)

---

## [10. FreeRider](./free-rider/)

### Context

In the buy function of the marketplace contract, it first sends the NFT ownership and then the buy value to the owner.

### Hack

Because the order of operations is wrong, you are basically buying NFTs for free, because this purchase price will be repaid. So just do that until you have all the NFTs and pay back flashswap with the additional fee at the end.

![Scheme](./assets/10.%20FreeRider.png)

---

## [11. Backdoor](./backdoor/)

### Context

We have a wallet registry that uses `GnosisSafeProxy` for additional security checks, but it doesn't check the fallback address and it doesn't check that the proxy caller is actually the owner of the proxy, so you could always remove the beneficiary by creating a custom proxy.

### Hack

With custom proxy you can program logic so that the proxy will send tokens to you using DVT token address because there's no blacklist of addresses that can be called as fallback. Basically on step 4 of the hack you try to call the transfer function on the proxy it will call the DVT contract as fallback because it doesn't exist on the contract itself and the proxy will just send all the tokens to you.

![Scheme](./assets/11.%20Backdoor.png)

---

## [12. Climber](./climber/)

### Context

You can make your contract a main proxy for a moment while executing `execute` function from `ClimberTimelock` contract.

### Hack

Make delay 0 so that the operation doesn't take time to be counted as mature, then give the climber vault proxy a proposer role to schedule an operation. After that you have everything to make the drain, pass all the operations you did to the `sweepFunds` function to schedule it so that the `execute` function will finish without any errors. Now everything is executed and you have all the previous privileges of the original `ClimberVault` contract, so you can just drain the entire token balance to the attacker's address.
![Scheme](./assets/12.%20Climber.png)
