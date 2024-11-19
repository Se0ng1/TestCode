# testcase

## Installation

This repo uses [Foundry](https://github.com/foundry-rs/foundry), if you don't have it installed, go [here](https://book.getfoundry.sh/getting-started/installation) for instructions. 

Once you cloned the repo, be sure to be located at the root and run the following command:

```
forge install 
```

## Usage 

All the examples are located under the test folder. 

To test all of them just run the following command: 

```
forge test -vv
```
* An alchemy key is provided, you don't need to add anything. 

To test a specific example run: 
```
forge test --match-path test/name-of-the-file -vv
```

따로 foundry.toml -> [rpc_endpoints]에 rpc 입력하셔야 합니다!

