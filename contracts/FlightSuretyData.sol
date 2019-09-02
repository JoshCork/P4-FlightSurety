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

     mapping(address => Airline) airlines; // Mapping for storing airlines that are registered

     uint private membershipCount = 1; // keep track of the total number of registered airlines


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
                return false; // this is a new vote
            }


        }

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
    function buy
                            (
                            )
                            external
                            payable
    {

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

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund
                            (
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Return Registered Airlines
    function fetchAirlines()
    external
    {

    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function()
                            external
                            payable
    {
        fund();
    }

}

