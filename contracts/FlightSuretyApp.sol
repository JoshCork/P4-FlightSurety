pragma solidity ^0.5.11;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    address dataContract;   // Address of data contract
    FsData fsData;          // Instance of data contract  used to call into it.
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees, used later as mock
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }
    mapping(bytes32 => Flight) private flights;
    uint buyIn = 10 ether; // 10 ether to buy into the registration
    uint public currentVotesNeeded;

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational()
    {
         // TODO: Modify to call data contract's status
        require(true, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    modifier requireMaxEther() //TODO: make this a constant instead of a hard coded number
    {
        require(msg.value <= 1 ether, "Cannot insure for more than 1 ether of value.");
        _;
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

      // Define a modifier that checks if they have sent enough to buy in. Returns change if they have
      // sent more than is required.
    modifier paidEnough() {
        uint _buyIn = buyIn;
        require(msg.value >= _buyIn,"Have not satisfied the buy-in amount.");
        uint amountToReturn = msg.value - _buyIn;
        msg.sender.transfer(amountToReturn);
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    * TODO: Need to modify this so that the first airline is registered on the contact being
    * initialized.
    */
    constructor (address dataContract) public
    {
        fsData = FsData(dataContract);
        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational()
                            public
                            pure
                            returns(bool)
    {
        return true;  // TODO: Modify to call data contract's status
    }

    function calcVotesNeeded(uint memberCount) public returns(uint) {
        uint denom = 2; // 50%
        uint num = memberCount;
        uint votesNeeded;
        if (num.mod(denom) > 0) {
            votesNeeded = num.div(denom) + 1;
        } else {
            votesNeeded = num.div(denom);
        }

        return votesNeeded;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   //TODO: only exisiting airlines should be able to nominate a new airline
   function nominateAirline(address account, string calldata airlineName)
    external //TODO: constrain to only airlines being able to nominate an airline.

   {
       bool isRegistered = fsData.isAirlineRegistered(account);
       require(!fsData.isAirlineApproved(account), "Airline is already registered and approved.");

       address nominatingAirline = msg.sender;

        if(isRegistered){
            require(!fsData.hasVoted(nominatingAirline,account), "This is a duplicate vote.");
            fsData.nominateAirline(nominatingAirline, account);
        } else {
            fsData.registerAirline(account, airlineName, false, msg.sender); // register a new airline but do not approve
        }

   }

   // application counterpart to data contract where data on policies is stored.
   function insureFlight (address account, string calldata flightNumber, uint flightTimestamp)
   requireMaxEther()
   external
   payable
   {

       bytes32 fKey = fsData.getFlightKey(account,flightNumber,flightTimestamp);
       bool hasPolicy = fsData.hasFlightPolicy(account, fKey);
       require(hasPolicy == false, "Flight has already been insured for this account.");
       fsData.buy(account, flightNumber, msg.value, fKey);

   }

   function creditPassenger (address airline, address account, string calldata flightNbr, uint256 flightTime) external  returns(string memory){
       bytes32 flightKey = fsData.getFlightKey(account, flightNbr, flightTime);
       require(fsData.hasFlightPolicy(account, flightKey),"This flight is not insured for this account");
       string statusMsg = "";
       // TODO: Check to see if flight status has already been recorded and proceed accordingly
       if(isFlightLogged(flightKey)){
           if(getFlightLog(flightKey) == STATUS_CODE_LATE_AIRLINE) {// The airline is late --> time to pay up!
               // Determine the amount of insurance that was placed on this flight by this passenger
                ( , ,uint iAmount, , ) = fsData.getPolicy(account, flightKey);

                // Use safemath to determin the payout based on the constant payout amount
                uint payout = iAmount.div(4).mul(6); //TODO: make this so it isn't hard coded into the contract and instead use a constant

                // Call creditInsuree() passing along the account, flightkey, and the payout amount calculated here.
                fsData.creditInsuree(account, payout, flightKey);
                statusMsg = "Account has been credited";
                return statusMsg;
           } else {
               statusMsg = "Flight delay reason is not elligeable for payout.";
               return statusMsg;
           }

       } else { // --> Request oracle input for flight
               fetchFlightStatus(airline,flightNbr,flightTime);
               statusMsg = "Flight status has been requested, please try again later";
               return statusMsg;
           }
   }

   // payPassenger transfers the amount of Ether that they have in their credit account from insurance payouts
   function payPassenger() external {
       uint balance = fsData.getCreditAmount(msg.sender);
       fsData.clearCredits(msg.sender);
       msg.sender.transfer(balance);
   }


   /** Register Airline
    * @dev Add an airline to the registration queue
    * first four airlines can register themselves, subsequent airlines need to be voted in.
    */
    function registerAirline(address account, string calldata airlineName)
                            external payable
                            paidEnough()
                            returns(bool success)
    {

        // registeredCount: Check to see how many airlines are already registered
        // registeredCount < 4, automatically register airline
        if (fsData.getMemberCount() <= 4) {
            require(!fsData.isAirlineRegistered(account), "Airline is already registered.");
            require(fsData.isAirlineRegistered(msg.sender), "Airline must be registered by another airline.");
            fsData.registerAirline(account, airlineName, true, msg.sender);
            return (true);
        } else {
            uint currentMembers = fsData.getMemberCount();
            uint votesNeeded = calcVotesNeeded(currentMembers);
            currentVotesNeeded = votesNeeded;
            uint currentVoteCount = fsData.getVoteCount(account);
            require(currentVoteCount >= votesNeeded, "You do not have enough votes yet"); // check for voteCount > 50% of member count
            fsData.approveAirline(account); // assuming it is, call approve airline
        }
    }


   /** Register Flight
    * @dev Register a future flight for insuring.
    *
    */
    function registerFlight
                                (
                                )
                                external
                                pure
    {

    }

   /** Process Flight Status
    * @dev Called after oracle has updated flight status
    *
    **/
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                                pure
    {
        bytes32 fKey = fsData.getFlightKey(account,flightNumber,flightTimestamp);
        fsData.logFlightStatus(fKey, statusCode);
    }



    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string calldata flight,
                            uint256 timestamp
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    }

    /********************************************************************************************/
    /*                                    region ORACLE MANAGEMENT                              */
    /********************************************************************************************/

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);

    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns (uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string calldata flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");

        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (
                                address account
                            )
                            internal
                            returns(uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    /********************************************************************************************/
    /*                                END region ORACLE MANAGEMENT                              */
    /********************************************************************************************/

}

contract FsData {
    // Placeholder for Interface to Data Contract
    struct Airline {
        string      name;
        address     aAccount;       // wallet address, used to uniquely identify the airline account
        bool        isRegistered;    // allows to de-register an airline
    }
    mapping(address => Airline) airlines;
    function registerAirline(address account, string calldata airlineName, bool approvalStatus, address msgSender) external {} // interface
    function isAirlineRegistered(address account) external returns (bool) {} // interface into data contract
    function getMemberCount() external returns(uint) { } // interface into data contract
    function isAirlineApproved(address account) external returns(bool) {} // interface into data contract
    function hasVoted(address nominatingAirline, address nominee) external returns (bool) {} // interface into data contract
    function nominateAirline(address nominatingAirline, address nominee) external {} // interface
    function approveAirline(address account) external {} // interface
    function getVoteCount(address account) external returns(uint) {} //interface
    function getFlightKey(address airline, string calldata flight, uint256 timestamp) pure external returns(bytes32) {} // interface
    function hasFlightPolicy(address account, bytes32 flightKey) external returns(bool) {} // interface
    function buy (address account, string calldata flightNumber, uint premiumPaid, bytes32 flightKey) external {} //interface
    function creditInsuree(address account, uint payout, bytes32 flightKey) external {} //interface
    function getPolicy(address account, bytes32 flightKey) external returns(address, string memory, uint, bool,bytes32) {} // interface
    function getCreditAmount(address account) external returns (uint) {} // interface
    function clearCredits(address account) external {} // interface
    function logFlighStatus(bytes32 fKey, uint8 sCode) external {} //interface
    function isFlightLogged(bytes32 fKey) external returns(bool) {} // interface

}

