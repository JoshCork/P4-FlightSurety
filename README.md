# FlightSurety

Help pretty please!  I'm currently stuck on this project.  I've reached out to the mentors for help but they don't seem to be able to help me (though Lorenzo helped me for quite a while). I'm submitting this in hopes of getting a review and some much needed help.

## Current Status

### Working

- I can register airlines and after the first 5 they can register themselves
- Multiparty registration is working
- I can register oracles and emit events
- I can insure a flight for a passenger
- Passenger can be credited 1.5x amount paid for insurance
- Passenger can withdrawl their credits
- Unit tests for all of the above are passing

### Known issues

- npm run dapp seems to work and I can interact with the contract purchasing insurance but when I go to submit a credit request if fails on my modifier saying that the flight was never registered
- there is no ui element to allow the account holder to withdraw their credits
- I've not yet implemented isOperational

### Help Needed

I've tried everything I can to debug the issue but am at a loss as to how to go any further with my debugging.  Specifically, things I've tried (that you'll see in the code):

- Emit events so that I can watch and see how they are being picked up.  --> Ganache fails to register any events coming through?
- Return data that was passed in to the function that is being used for "require" --> values seem to match?

Weirdness I've observed:

- When looking at the Ganache UI it looks like no transactions are hitting my deployed contracts after I migrate them.
- I can insure the same flight multiple times for the same person.  My modifier should not allow this.
- I've tried with both the CLI and the GUI for Ganache with the same results
- I don't see any of my events coming throuigh the Ganache UI
- I suspect there is something wrong with my config or contract js.... that the FS App Contract is talking to the wrong instance of the FS Data contract or not talking to it at all?

### Running the project

- pull the code from my repo
- switch to Website branch `git checkout Website`
- run `npm install`
- start ganache gui (or do a find and replace for port number 7545 to 8545)
- run `truffle compile`
- run `truffle migrate --reset`
- run `npm run dapp`

## PREVIOUS README:

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