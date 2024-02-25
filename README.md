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
