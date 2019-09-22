import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {

            this.owner = accts[0];
            this.airline = accts[2];

            let counter = 1;

            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    insureFlight(eAmount,flight,fTime, callback){
        let self = this;
        let premium = this.web3.utils.toWei(eAmount.toString(), 'ether')

        console.log(`timestamp: ${fTime}`)
        console.log(`this.passengers[0]: ${this.passengers[0]}`)
        console.log(`flightNumber: ${flight}`)
        console.log(`premium: ${premium}`)
        console.log(`emount: ${eAmount}`)


        self.flightSuretyApp.methods
            .insureFlight(this.passengers[0], flight, fTime)
            .call({from:this.owner, value: premium}, callback);
    }

    creditPassenger(flightNbr, flightTime, callback){
        let self = this;

        console.log(`timestamp: ${flightTime}`)
        console.log(`this.passengers[0]: ${this.passengers[0]}`)
        console.log(`flightNumber: ${flightNbr}`)

        self.flightSuretyApp.methods
            .creditPassenger(this.airlines[0], this.passengers[0], flightNbr, flightTime)
            .call({from:this.owner}, callback);
    }

    debugHasFlightPolicy(flightNbr, flightTime, callback){
        let self = this;
        console.log(`timestamp: ${flightTime}`)
        console.log(`this.passengers[0]: ${this.passengers[0]}`)
        console.log(`flightNumber: ${flightNbr}`)

        self.flightSuretyApp.methods
            .debugHasFlightPolicy(this.passengers[0], flightNbr, flightTime)
            .call({from:this.owner}, callback);

    }

    debugPolicy(callback){
        let self = this;
        self.flightSuretyApp.methods
            .debugPolicy(this.passengers[0])
            .call({from:this.owner}, callback);
    }


    debugFlightKey(flightNbr, flightTime, callback){
        let self = this;
        console.log(`timestamp: ${flightTime}`)
        console.log(`this.passengers[0]: ${this.passengers[0]}`)
        console.log(`flightNumber: ${flightNbr}`)

        self.flightSuretyApp.methods
            .debugFlightKey(this.passengers[0], flightNbr, flightTime)
            .call({from:this.owner}, callback);

    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }
}