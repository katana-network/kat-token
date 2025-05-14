## kat-token

Native token of the Katana Network Chain.

### Features

- standard ERC20
- permit
- configurable inflation
- locked for first 9 months, with early unlock mechanism
- immutable

### Test

Run:  
`forge soldeer install`

Next:  
`forge test`

### Deploy

1. Set a private key and other data in `.env`
2. Set a rpc endpoint in `foundry.toml`
3. Run `forge script script/Deploy.s.sol --rpc-url katana_mainnet --broadcast --verify`
