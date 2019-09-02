
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    // await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address); // unclear what the purpose of this is? Not covered in the ruberic or the lessons?
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

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

  it('When calculating votes needed if 50% does not divide evenly round up by 1', async () => {

    // ARRANGE

    let numerator = 9
    var result

    // ACT
    try {
        await config.flightSuretyApp.calcVotesNeeded(9);
    }
    catch(e) {
        console.log(e)
    }

    result = config.flightSuretyApp.currentVotesNeeded();

    // ASSERT
    assert.equal(result, 5, "is this math really safe?");

  });


});
