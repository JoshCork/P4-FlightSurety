
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';
import Web3 from 'web3';

(async() => {


    let web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:7545'));
    let result = null;
    let accounts = await web3.eth.getAccounts();

    console.log(`account 11: ${accounts[11]}`);



    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            console.log("I'm in isOperational yo.")
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });


        // User-submitted transaction --> Not called directly in my HTML
        // DOM.elid('submit-oracle').addEventListener('click', () => {
        //     console.log("I've clicked the submit-oracle button yo!")
        //     let flight = DOM.elid('flight-number').value;
        //     // Write transaction
        //     contract.fetchFlightStatus(flight, (error, result) => {
        //         display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
        //     });
        // })


         // User-submitted transaction
         DOM.elid('insure-flight').addEventListener('click', () => {
            console.log("I've clicked the insure-flight button yo!")
            let flight = DOM.elid('flight-number').value;
            let flightTime = DOM.elid('flight-time').value;
            let eAmount = DOM.elid('ether-amount').value;
            let passenger = accounts[11];
            console.log(`flightTime: ${flightTime}`)
            // Write transaction
            contract.insureFlight(eAmount, passenger, flight, flightTime, (error, result) => {
                console.log(error,result);
                display('Flight Insurance', 'This flight should have been insured', [ { label: 'Flight Insurance', error: error, value: result} ]);
            });
        })

        // User-submitted transaction
        DOM.elid('payout-flight').addEventListener('click', () => {
            console.log("I've clicked the payout-flight button yo!")
            let flight = DOM.elid('flight-number-payout').value;
            let flightTime = DOM.elid('flight-time-payout').value;
            let airline = accounts[2];
            let passenger = accounts[11];

            console.log(`flightTime: ${flightTime}`)
            console.log(`airline: ${airline}`)
            console.log(`html flight: ${flight}`)
            console.log(`html passenter: ${passenger}`)
            // Write transaction
            contract.creditPassenger(airline, passenger, flight, flightTime, (error, result) => {
                console.log(error,result);
                display('Reimbursement Status', 'We have made the request', [ { label: 'Flight Insurance', error: error, value: result} ]);
            });
        })

    });


})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







