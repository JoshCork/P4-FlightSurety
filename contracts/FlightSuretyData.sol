pragma solidity ^0.5.11;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;   // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false


    struct Airline {
        string                      name;
        address                     aAccount;      // wallet address, used to uniquely identify the airline account
        bool                        isFounder;     // is this a founding airline?
        bool                        isRegistered;  // allows to de-register an airline
        bool                        isApproved;    // has this airline been voted in?
        uint                        voteCount;     // count of votes used to nominate this airline to be registered
        address[]                   voters;        // members that voted this airline in. used to prevent duplicate votes
    }

    struct Policy {
        address pHolder;        // Wallet Address of the Policy Holder (the person that purchased inssurance and will need to be paid out)
        string  flightNumber;   // flight number that this policy covers
        uint    premiumPaid;    // Amount of Ether paid to the policy for this flight by this address
        bool    isRedeemed;     // Tracks whether this policy has been cashed out or not (redeemed)
        bytes32 flightKey;      // FlightKey is used as a unique identifier for the insurance record. It combines the airline, the flight number, and the flight timestamp

    }

    mapping(address => Policy[]) policies;  // Mapping of address (policy holders) to an array of polcies
    mapping(address => Airline) airlines;   // Mapping for storing airlines that are registered
    uint private membershipCount = 1;       // keep track of the total number of registered airlines


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    address firstAirline
                                )
                                public
    {
        contractOwner = msg.sender;
        airlines[firstAirline] = Airline({
                name: "Founding Airline",
                aAccount: firstAirline,
                isFounder: true,
                isRegistered: true,
                isApproved: true,
                voteCount: 1,
                voters: new address[](0)
        });
    }

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
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /*
    * Source: https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity
    * Truffle wasn't playing nice with import "github.com/Arachnid/solidity-stringutils/strings.sol";
    * So I used the strategy from the above website.
    */
    function compareStrings (string memory a, string memory b)
    public view
    returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))) );
       }

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational()
                            public
                            view
                            returns(bool)
    {
        return operational;
    }

    function getMemberCount() external returns(uint) {
        return membershipCount;
    }

    function getVoteCount(address account) external returns(uint){
        return airlines[account].voteCount;
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus
                            (
                                bool mode
                            )
                            external
                            requireContractOwner
    {
        operational = mode;
    }

    /**
    * @dev Check if an airline is registered
    * @return A bool that indicates if the airline is registered
    */
    function isAirlineRegistered(address account)
        external
        view
        returns (bool)
    {
        return airlines[account].isRegistered;
    }

    /**
    * @dev Check if an airline is registered
    * @return A bool that indicates if the airline is registered
    */
    function isAirlineApproved(address account)
        external
        view
        returns (bool)
    {
        return airlines[account].isApproved;
    }

    function hasVoted(address nominatingAirline, address nominee)
        external
        returns (bool)
    {
        if (airlines[nominee].voters.length == 0) {
            return false;
        } else { // there are already some votes, check to see if this nominatingAirline is already one of them
            for(uint i=0; i<airlines[nominee].voters.length; i++) {
                if(airlines[nominee].voters[i] == nominatingAirline){
                    return true; // found a vote from this nominating airline
                }
                return false; // this is a new vote //FIXME: i++ is never reached if the second vote  is this nominated airline it won't get flagged
            }


        }

    }

    /* hasPolicy: returns bool indicating if a policy account has been created already for this account */
    function hasPolicy(address account) internal returns (bool) {
        if (policies[account].length == 0) {
            return false;
        } else {
            return true;
        }
    }

    function getPolicyLength(address account) external returns(uint) {
        return policies[account].length;
    }

    function hasFlightPolicy(address account, bytes32 flightKey) external returns(bool) {
        for (uint i = 0; i < policies[account].length; i++) {
            if (policies[account][i].flightKey == flightKey) {
                return true; // policy exists for this flight number
            }
        }
        return false; // flight number not found in list of policies
    }

    function getPolicy(address account, bytes32 flightKey) external returns(address, string memory, uint, bool,bytes32) {
        for (uint i = 0; i < policies[account].length; i++) {
            if (policies[account][i].flightKey == flightKey) {
                return (
                    policies[account][i].pHolder,
                    policies[account][i].flightNumber,
                    policies[account][i].premiumPaid,
                    policies[account][i].isRedeemed,
                    policies[account][i].flightKey
                    );
            }
        }
        // policy not found.  What do I return here?
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function registerAirline(address account, string calldata airlineName, bool approvalStatus, address msgSender)
        external
        requireIsOperational
        {
            // require(!airlines[account].isRegistered, "Airline is already registered.");
            // require(airlines[tx.origin].isRegistered, "Airline must be registered by another airline.");
           if (approvalStatus) { // airline is approved, this is a founder
                airlines[account] = Airline({
                name: airlineName,
                aAccount: account, // this is redundant but a placeholder for more fields.
                isRegistered: true,
                isApproved: approvalStatus,
                isFounder: true,
                voteCount: 1,
                voters: new address[](0)
                });
                membershipCount = membershipCount + 1;
            } else { // airline is not approved, this is a new nominee
                airlines[account] = Airline({
                name: airlineName,
                aAccount: account, // this is redundant but a placeholder for more fields.
                isRegistered: true,
                isApproved: approvalStatus,
                isFounder: false,
                voteCount: 1,
                voters: new address[](0)
                });
                airlines[account].voters.push(msgSender);
            }
        }

    /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function approveAirline(address account)
        external
        requireIsOperational
        {
            airlines[account].isApproved = true;
            membershipCount = membershipCount + 1;
        }

    function nominateAirline(address nominatingAirline, address nominee)
        external
        requireIsOperational
    {
        airlines[nominee].voters.push(nominatingAirline);
        airlines[nominee].voteCount = airlines[nominee].voteCount + 1;
    }

   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy (address account, string calldata flightNumber, uint premiumPaid, bytes32 flightKey)
        external
        // payable // nope, application logic will be payable?
    {
        // check to see if they currently have a policy in the policies mapping
        if (hasPolicy(account)) {
            // has account: so we need to add a new policy for this flight to the array of policies
            Policy memory newPolicy  = Policy({
                pHolder: account,
                flightNumber: flightNumber,
                premiumPaid: premiumPaid,
                isRedeemed: false,
                flightKey: flightKey
            });
            policies[account].push(newPolicy);
        } else {
            // doesn't have account: so we need to create an account in policies and add a new policy to the array for this flight
            Policy memory newPolicy  = Policy({
                pHolder: account,
                flightNumber: flightNumber,
                premiumPaid: premiumPaid,
                isRedeemed: false,
                flightKey: flightKey
            });
            policies[account].push(newPolicy);
        }
    }



    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }


    function getFlightKey
                        (
                            address airline,
                            string calldata flight,
                            uint256 timestamp
                        )
                        pure
                        external
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    // function()
    //                         external
    //                         payable
    // {
    //     fund();
    // }

}

