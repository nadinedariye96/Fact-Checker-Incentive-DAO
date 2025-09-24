# 🔍 Fact-Checker Incentive DAO

> **Combating Misinformation Through Decentralized Truth Verification** 🛡️

## 🌟 Overview

The Fact-Checker Incentive DAO is a revolutionary smart contract that incentivizes community-driven fact-checking through a reputation-based token economy. Built on Stacks blockchain, it empowers communities to verify news claims, combat misinformation, and build decentralized trust systems.

## 🎯 Core Features

### ✅ **Claim Submission & Verification**
- Submit news claims with content hash and descriptive text
- Stake tokens to ensure quality submissions
- Community-based voting system for verification

### 🗳️ **Decentralized Voting**
- Weighted voting based on staked tokens
- Time-limited voting periods (1440 blocks)
- Support/oppose claims with financial backing

### 🏆 **Reputation System**
- Track accuracy scores for all participants
- Reward accurate fact-checkers with reputation points
- Build long-term credibility in the community

### ⚖️ **Dispute Resolution**
- Challenge resolved claims through staking mechanism
- Arbitration system for contentious decisions
- Fair resolution through economic incentives

### 💰 **Token Economy**
- FACT tokens for participation and rewards
- Treasury management for sustainable rewards
- Transfer and balance management functions

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for interaction

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/your-username/Fact-Checker-Incentive-DAO.git
cd Fact-Checker-Incentive-DAO
```

2. **Initialize the contract:**
```bash
clarinet check
```

3. **Run tests:**
```bash
npm install
npm test
```

## 📋 Contract Functions

### 🔧 **Administrative Functions**

#### `initialize()`
Initialize the contract with initial token supply and treasury.
- **Access:** Contract owner only
- **Mints:** 1,000,000 FACT tokens
- **Sets:** Treasury balance to 500,000 tokens

#### `mint-tokens(recipient, amount)`
Mint new FACT tokens to a specified recipient.
- **Access:** Contract owner only
- **Parameters:** 
  - `recipient`: Principal address
  - `amount`: Number of tokens to mint

### 📝 **Core Functionality**

#### `submit-claim(content-hash, claim-text)`
Submit a new fact-checking claim.
- **Stake Required:** 1,000 FACT tokens minimum
- **Parameters:**
  - `content-hash`: 32-byte hash of content
  - `claim-text`: ASCII description (max 256 chars)
- **Returns:** Unique claim ID

#### `vote-on-claim(claim-id, support, stake-amount)`
Vote to support or oppose a claim.
- **Parameters:**
  - `claim-id`: ID of the claim to vote on
  - `support`: true (support) or false (oppose)
  - `stake-amount`: Tokens to stake (minimum 10)
- **Deadline:** 1440 blocks after claim submission

#### `resolve-claim(claim-id)`
Finalize voting results for a claim.
- **Timing:** After voting period expires
- **Rewards:** Distribute tokens to accurate voters
- **Updates:** Reputation scores for participants

#### `create-dispute(claim-id, challenger-stake)`
Challenge a resolved claim through dispute mechanism.
- **Stake Required:** 2x minimum stake (2,000 FACT tokens)
- **Parameters:**
  - `claim-id`: ID of claim to dispute
  - `challenger-stake`: Tokens to risk in dispute

#### `arbitrate-dispute(dispute-id, resolution)`
Resolve disputes through arbitration.
- **Access:** Contract owner only
- **Parameters:**
  - `dispute-id`: ID of dispute to resolve
  - `resolution`: true (challenger wins) or false (original claim stands)

### 📊 **Query Functions**

#### `get-claim(claim-id)`
Retrieve detailed claim information.

#### `get-user-reputation(user)`
Get reputation metrics for any user:
- Overall accuracy score
- Total votes cast
- Number of accurate votes

#### `get-balance(user)`
Check FACT token balance for any user.

#### `get-vote(claim-id, voter)`
View specific vote details.

#### `get-dispute(dispute-id)`
Retrieve dispute information.

#### `get-total-claims()`
Get total number of claims submitted.

#### `get-treasury-balance()`
Check current treasury balance.

## 💡 Usage Examples

### Submitting a Claim
```clarity
(contract-call? .fact-checker-incentive-dao submit-claim 
  0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
  "Breaking: Major tech company announces new product")
```

### Voting on a Claim
```clarity
(contract-call? .fact-checker-incentive-dao vote-on-claim 
  u1 true u500)  ;; Support claim #1 with 500 FACT tokens
```

### Checking Reputation
```clarity
(contract-call? .fact-checker-incentive-dao get-user-reputation 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## 🎖️ Reputation System

The DAO tracks three key metrics for each participant:

- **🎯 Accuracy Score**: Percentage of correct votes (0-100%)
- **📊 Total Votes**: Lifetime participation count
- **✅ Accurate Votes**: Number of correct predictions

Higher reputation scores lead to increased influence and better rewards.

## ⚠️ Important Constants

- **Minimum Stake:** 1,000 FACT tokens
- **Voting Period:** 1,440 blocks (~24 hours)
- **Arbitration Period:** 2,880 blocks (~48 hours)
- **Base Reward:** 100 FACT tokens
- **Dispute Stake:** 2x minimum stake

## 🛡️ Security Features

- ✅ Owner-only administrative functions
- ✅ Stake-based participation to prevent spam
- ✅ Time-locked voting periods
- ✅ Economic incentives for honest behavior
- ✅ Dispute resolution mechanism
- ✅ Reputation-based trust system

## 🤝 Contributing

We welcome contributions to improve the Fact-Checker Incentive DAO! Please:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🌐 Community

Join our mission to combat misinformation through decentralized verification:

- **Discord:** [Join our community](https://discord.gg/fact-checker-dao)
- **Twitter:** [@FactCheckerDAO](https://twitter.com/FactCheckerDAO)
- **Governance Forum:** [Discuss proposals](https://forum.factcheckerdao.org)

---

**Built with ❤️ for truth and transparency on the Stacks blockchain** 🌍
