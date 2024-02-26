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

## 1. Unstoppable

### Context

UnstoppableLender's function `flashLoan` checks balance via storage variable and comparing it to the actual balance of the contract using token's `balanceOf` function.

### Hack

Simply send tokens so that the actual token balance of the contract is not equal to the value of the `poolBalance` variable.

![Scheme](./assets/1.%20Unstoppable.png)

---

## 2. Naive receiver

### Context

We have flashloan contract with the `FEE` of 1 ETH - `NaiveReceiverLanderPool`. And we have contract that could take flashloans from this contract and it should repay this huge fee after every flashloan - `FlashLoanReceiver`.

### Hack

Call flashloan until `FlashLoanReceiver` isn't drained, because it has a balance of 10 ETH and the fee is 1 ETH - you should call it 10 times until the contract isn't drained.

![Scheme](./assets/2.%20Naive%20Receiver.png)

---

### 3. Truster

### Context

We have flashloan contract that can execute any function name and parameters for the user of the contract. (It is much more convenient for the user to pass his own logic than to use an already prepared function that he has to implement, right?😉)

### Hack

Just encode approve data of the DVT token to our attacker's address and drain all value from the contract.

![Scheme](./assets/3.%20Truster.png)

---

### 4. Side Entrance

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

### 5. The Rewarder

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

### 6. Selfie

### Context

We have pool and governance contract that allows voters to schedule some actions on the pool. Also the pool gives flashloan of the governance token and there are no fees.

### Hack

Take the flashloan of the governance token and schedule a `drainAllFunds` function, then send all the tokens back. You can do this because you became the largest voter in the governance contract at the time of the flashloan.
![Scheme](./assets/6.%20Selfie.png)

---

### 7. Compromised

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

### 8. Puppet

### Context

We have Uniswap V1 pool with small amounts of tokens in it and therefore the pool is very volatile.

### Hack

Because TVL is small, we can manipulate the price of the tokens within it and make one asset worth much more than another.
![Scheme](./assets/8.%20Puppet.png)

---

### 9. PuppetV2

### Context

The same as in PupperV1, but it uses UniswapV2 version.

### Hack

The same as in PuppetV1 works for PuppetV2, but the values are more limited.
![Scheme](./assets/8.%20Puppet.png)
