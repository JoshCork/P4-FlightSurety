import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
const TEST_ORACLES_COUNT = 100;
let fee = await flightSuretyApp.REGISTRATION_FEE.call();

// Register a bunch of oracles with randomized indexes
for(let a=1; a<TEST_ORACLES_COUNT; a++) {
  await flightSuretyApp.registerOracle({ from: web3.eth.accounts[a], value: fee });
  let result = await flightSuretyApp.getMyIndexes.call({from: web3.eth.accounts[a]});
  console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
}


flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    console.log(event)
});

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;