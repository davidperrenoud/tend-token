/**
 * @title ICO token
 * @version 1.0
 * @author Patrice Juergens <pj@validitylabs.org>
 */
pragma solidity ^0.4.18;

import "../../../node_modules/zeppelin-solidity/contracts/token/MintableToken.sol";
import "./DividendToken.sol";

contract IcoToken is DividendToken, MintableToken {
    string public constant name = "ICO Token";
    string public constant symbol = "ICT";
    uint8 public constant decimals = 18;

    // DividendToken public dividendToken;

    /**
     * @dev Constructor of IcoToken that instantiate a new DividendToken
     */
    function IcoToken() public DividendToken(msg.sender) {
        // call base constructor from dividend token
        // dividendToken = DividendToken(msg.sender);
    }
}
