import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';

(async() => {
console.log("server is starting up.")
let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
let accounts = await web3.eth.getAccounts();

console.log(accounts)

let flightSuretyApp = new web3.eth.Contract(
  FlightSuretyApp.abi
  , config.appAddress
  ,{gasPrice:'20000000000'
  ,gasLimit:'6721975'});
const TEST_ORACLES_COUNT = 80;
let fee = web3.utils.toWei('1', 'ether');

// console.log(flightSuretyApp)


  // Register a bunch of oracles with randomized indexes
  for(let a=1; a<TEST_ORACLES_COUNT; a++) {
    console.log(`I should now be registering some oracles value of count: ${a}`);
    await flightSuretyApp.methods.registerOracle().send({ from: accounts[a], value: fee });
    let result = await flightSuretyApp.methods.getMyIndexes().call({ from: accounts[a] });
    console.log(`results: ${JSON.stringify(result)}`)
    console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
  }

flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    console.log(event)
});

flightSuretyApp.events.InsuranceInfo({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log(event)
});

console.log("server is up and running")
})();

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})
export default app;