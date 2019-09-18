
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
var moment = require('moment');


contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    // await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address); // unclear what the purpose of this is? Not covered in the ruberic or the lessons?
  });

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");

  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");

  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {

    // ARRANGE
    let newAirline = accounts[2];
    let airlineName = "Udacity Air";

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, airlineName, {from: config.firstAirline});
    }
    catch(e) {
        // console.log(e)
    }
    let result = await config.flightSuretyData.isAirlineRegistered.call(newAirline);

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) can register an Airline using registerAirline() when funded', async () => {

    // ARRANGE
    let newAirline = accounts[3];
    let airlineName = "Udacity Air";
    let msgValue = web3.utils.toWei('10', 'ether')

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, airlineName, {from: config.firstAirline, value: msgValue});
    }
    catch(e) {
        console.log(e)
    }
    let result = await config.flightSuretyData.isAirlineRegistered.call(newAirline);

    // ASSERT
    assert.equal(result, true, "Airline should be able to register another airline if it has provided funding (10 Ether)");

  });

  it('Should not be registered if not founding four, and not yet nominated', async () => {

    // ARRANGE
    let airOne = accounts[4];
    let airTwo = accounts[5];
    let airThree = accounts[6];
    let airFour = accounts[7];
    let rogueAir = accounts[8];

    let airlineName = "test airline"
    let msgValue = web3.utils.toWei('10', 'ether')

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(airOne, airlineName, {from: config.firstAirline, value: msgValue}); //founder2
        await config.flightSuretyApp.registerAirline(airTwo, airlineName, {from: config.firstAirline, value: msgValue}); //founder3
        await config.flightSuretyApp.registerAirline(airThree, airlineName, {from: config.firstAirline, value: msgValue}); //founder4
        await config.flightSuretyApp.registerAirline(rogueAir, airlineName, {from: rogueAir, value: msgValue}); // Non-Founder, needs votes
    }
    catch(e) {
        // console.log(e)
    }
    let result = await config.flightSuretyData.isAirlineRegistered.call(rogueAir);
    // console.log(`isAirlineApproved: ${result}`)

    // ASSERT
    assert.equal(result, false, "Airline should not be registered member count > 4 and not yet nominated");

  });

  it('Should be registered but not approved when nominated for the first time.', async () => {

    // ARRANGE
    let rogueAir = accounts[8];

    let airlineName = "test airline"

    // ACT
    try {
        await config.flightSuretyApp.nominateAirline(rogueAir, airlineName, {from: config.firstAirline});
    }
    catch(e) {
        // console.log(e)
    }
    let result1 = await config.flightSuretyData.isAirlineRegistered.call(rogueAir);
    let result2 = await config.flightSuretyData.isAirlineApproved.call(rogueAir);

    let result = result1 && !result2

    // ASSERT
    assert.equal(result, true, "Airline should have been registered but not approved");

  });

  it('Should be approved after enough votes have been cast.', async () => {

    // ARRANGE
    let approvalAir = accounts[9];
    let airlineName = "ApprovalAir"
    let existingAirStartCount = 4
    let memberCount = await config.flightSuretyData.getMemberCount.call();
    let votesNeeded = Math.ceil(memberCount/2)
    let msgValue = web3.utils.toWei('10', 'ether')

    // ACT
    for (i = 1; i <= votesNeeded; i++ ) { // Vote airline in
        await config.flightSuretyApp.nominateAirline(approvalAir, airlineName, {from: accounts[existingAirStartCount]});
        existingAirStartCount++
    }
    try { // register once there are enough votes
        await config.flightSuretyApp.registerAirline(approvalAir, airlineName, {from: approvalAir, value: msgValue});
    }
    catch(e) {
        console.log(e)
    }


    let result1 = await config.flightSuretyData.isAirlineRegistered.call(approvalAir);
    let result2 = await config.flightSuretyData.isAirlineApproved.call(approvalAir);
    let result = result1 && result2

    // ASSERT
    assert.equal(result, true, "Airline should have been registered and approved");

  });

  it('Passenger should be able to insure flight and can retrieve policy', async () => {

    // ARRANGE
    let consumer = accounts[11];
    let flightNumber = "SWA 1627"
    let premiumAmount = web3.utils.toWei('1', 'ether')
    let flightTime = moment(new Date("Wed, 11 September 2019 11:45:00 GMT")).unix()
    let flightKey = await config.flightSuretyData.getFlightKey.call(consumer,flightNumber,flightTime);


    // ACT

    try { // register once there are enough votes
        await config.flightSuretyApp.insureFlight(consumer, flightNumber, flightTime, {from: consumer, value: premiumAmount});
    }
    catch(e) {
        console.log(e)
    }

    let isInsured = await config.flightSuretyData.hasFlightPolicy.call(consumer, flightKey);
    let policy = await config.flightSuretyData.getPolicy.call(consumer, flightKey);

    // ASSERT
    assert.equal(isInsured, true, "Policy should have been created for account");
    assert.equal(consumer,policy[0], "Policy Holder Account is incorrect.")
    assert.equal(flightNumber, policy[1], "Flight number retrieved is incorrect.")
    assert.equal(premiumAmount,policy[2], "Premium Retrieved is incorrect")
    assert.equal(false,policy[3], "Policy Redemption Status is incorrect")
    assert.equal(flightKey,policy[4], "Flightkey retrieved is incorrect.")


  });

  it('Passenger should not be able to insure flight for more than 1 ether', async () => {

    // ARRANGE
    let consumer = accounts[12];
    let flightNumber = "SWA 2716"
    let premiumAmount = web3.utils.toWei('10', 'ether')
    let flightTime = moment(new Date("Wed, 11 September 2019 11:45:00 GMT")).unix()
    let flightKey = await config.flightSuretyData.getFlightKey.call(consumer,flightNumber,flightTime);


    // ACT

    try { // register once there are enough votes
        await config.flightSuretyApp.insureFlight(consumer, flightNumber, flightTime, {from: consumer, value: premiumAmount});
    }
    catch(e) {
        // console.log(e)
    }

    let isInsured = await config.flightSuretyData.hasFlightPolicy.call(consumer, flightKey);

    // ASSERT
    assert.equal(isInsured, false, "Policy should not have been created for account");



  });

  it('Passenger can be credited for flight delays and redemption recorded', async () => {

    // ARRANGE
    let consumer = accounts[11];
    let flightNumber = "SWA 1627"
    let premiumAmountEther = 1
    let multiplier = 1.5
    let creditAmountEther = premiumAmountEther * multiplier
    let expectedCredit = web3.utils.toWei(creditAmountEther.toString(), 'ether')
    let expectedRedemption = true
    let flightTime = moment(new Date("Wed, 11 September 2019 11:45:00 GMT")).unix()
    let flightKey = await config.flightSuretyData.getFlightKey.call(consumer,flightNumber,flightTime);


    // ACT

    try { // credit the account
        await config.flightSuretyApp.creditPassenger(consumer, flightKey, {from: consumer});
    }
    catch(e) {
        console.log(e)
    }

    let actualCredit = await config.flightSuretyData.getCreditAmount.call(consumer);
    let policy = await config.flightSuretyData.getPolicy.call(consumer, flightKey);
    let actualRedemption = policy[3]


    // ASSERT
    assert.equal(expectedCredit, actualCredit, "Expected Credit does not equal actual")
    assert.equal(expectedRedemption,actualRedemption, "Policy Redemption Status is incorrect")


    });

  it('Passenger can withdraw credit and credits are reset to zero', async () => {

    // ARRANGE
    let passenger = accounts[11];
    let expectedCredit = web3.utils.toWei("0", 'ether')
    let expectedIncreaseAbove = web3.utils.toWei("1.4", 'ether')
    let startingBalance = await web3.eth.getBalance(passenger)
    let startingCredit = await config.flightSuretyData.getCreditAmount.call(passenger);


    // ACT

    try { // credit the account
        await config.flightSuretyApp.payPassenger({from: passenger});
    }
    catch(e) {
        console.log(e)
    }

    let actualCredit = await config.flightSuretyData.getCreditAmount.call(passenger);
    let endingBalance = await web3.eth.getBalance(passenger)
    let actualIncrease = endingBalance - startingBalance
    let transactionFee = expectedIncreaseAbove - actualIncrease

    // console.log(`startingCredit:    ${startingCredit}`)
    // console.log(`actualCredit:      ${actualCredit}`)
    // console.log(`startingBalance:   ${startingBalance}`)
    // console.log(`endingBalance :    ${endingBalance}`)
    // console.log(`actualIncrease:    ${actualIncrease}`)
    // console.log(`transactionFee:    ${transactionFee}`)

    // ASSERT
    assert.equal(expectedCredit, actualCredit, "Expected Credit does not equal actual")
    // TODO: need to get the transaction number and look at the receipt and make sure the balance increases by the expected amount
    // assert.isAbove(expectedIncreaseAbove,actualIncrease, "Passenger did not receive correct payout")


    });



});
