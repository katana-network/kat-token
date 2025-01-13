## kat-token

Native token of the Katana Network Chain.

### Features

- standard ERC20
- permit
- MerkleMinter to distribute initial supply
- configurable inflation that starts 4 years after deployment
- locked for first 9 months, with early unlock mechanism
- immutable

### Test

Run:  
`forge soldeer install`

And:
`npm i`

Next:  
`forge test`

### Deploy

1. Set a private key and other data in `.env`
2. Set a rpc endpoint in `foundry.toml`
3. Set values in `script/Deploy.s.sol`
4. Run `forge script script/Deploy.s.sol --rpc-url polygon_mainnet --broadcast --verify`

### Additional Info

The repo also contains tools to build the merkle tree/root to be submitted to the MerkleMinter.  
Add a `utils/distribution.json` file of the same format as shown in `utils/exampleDistribution.json`.  
Run `npm i`.  
Run `npm run buildTree` to receive a `utils/tree.json` file and the merkle root in the cli.  
Examples on how to get a proof that can be submitted are shown in `utils/getProof.js`.

A more complete example is the `test/Claim.t.sol` file.