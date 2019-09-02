# FlightSurety


## Registration

If airline is one of first four
    --> Check for funding and register
    --> Set isApproved to true
    --> Set isFounder to true
If airline is 5th or after
    --> Check for vote counts
    --> If vote counts > 50% toggle registration
    --> Else reject registration: "not enough votes"

New Function: nominateAirline
    --> Check isRegistered && notApproved
    --> Check caller isAirline
    --> Check isRegistered && isApproved
        --> reject "airline registered and approved"
    --> if airline is NOT registered && notApproved
        --> Register & set isApproved to false set voteCount to 1
        --> Emit voteCount
    --> if airline is registered && notApproved
        --> increment vote count
        --> Emit voteCount


FlightSurety is a sample application project for Udacity's Blockchain course.

## Install

This repository contains Smart Contract code in Solidity (using Truffle), tests (also using Truffle), dApp scaffolding (using HTML, CSS and JS) and server app scaffolding.

To install, download or clone the repo, then:

`npm install`
`truffle compile`

## Develop Client

To run truffle tests:

`truffle test ./test/flightSurety.js`
`truffle test ./test/oracles.js`

To use the dapp:

`truffle migrate`
`npm run dapp`

To view dapp:

`http://localhost:8000`

## Develop Server

`npm run server`
`truffle test ./test/oracles.js`

## Deploy

To build dapp for prod:
`npm run dapp:prod`

Deploy the contents of the ./dapp folder


## Resources

* [How does Ethereum work anyway?](https://medium.com/@preethikasireddy/how-does-ethereum-work-anyway-22d1df506369)
* [BIP39 Mnemonic Generator](https://iancoleman.io/bip39/)
* [Truffle Framework](http://truffleframework.com/)
* [Ganache Local Blockchain](http://truffleframework.com/ganache/)
* [Remix Solidity IDE](https://remix.ethereum.org/)
* [Solidity Language Reference](http://solidity.readthedocs.io/en/v0.4.24/)
* [Ethereum Blockchain Explorer](https://etherscan.io/)
* [Web3Js Reference](https://github.com/ethereum/wiki/wiki/JavaScript-API)