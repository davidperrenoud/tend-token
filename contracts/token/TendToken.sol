/**
 * @title TEND token
 * @version 2.0
 * @author Validity Labs AG <info@validitylabs.org>
 *
 * The TTA tokens are issued as participation certificates and represent
 * uncertificated securities within the meaning of article 973c Swiss CO. The
 * issuance of the TTA tokens has been governed by a prospectus issued by
 * Tend Technologies AG.
 *
 * TTA tokens are only recognized and transferable in undivided units.
 *
 * The holder of a TTA token must prove his possessorship to be recognized by
 * the issuer as being entitled to the rights arising out of the respective
 * participation certificate; he/she waives any rights if he/she is not in a
 * position to prove him/her being the holder of the respective token.
 *
 * Similarly, only the person who proves him/her being the holder of the TTA
 * Token is entitled to transfer title and ownership on the token to another
 * person. Both the transferor and the transferee agree and accept hereby
 * explicitly that the tokens are transferred digitally, i.e. in a form-free
 * manner. However, if any regulators, courts or similar would require written
 * confirmation of a transfer of the transferable uncertificated securities
 * from one investor to another investor, such investors will provide written
 * evidence of such transfer.
 */
pragma solidity ^0.4.24;

import "../../node_modules/zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "../../node_modules/zeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "../../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./DividendToken.sol";

contract TendToken is MintableToken, PausableToken, DividendToken {
    using SafeMath for uint256;

    string public constant name = "Tend Token";
    string public constant symbol = "TTA";
    uint8 public constant decimals = 18;

    // Minimum transferable chunk
    uint256 public granularity = 1e18;

    /**
     * @dev Constructor of TendToken that instantiate a new DividendToken
     */
    constructor() public DividendToken() {
        // token should not be transferrable until after all tokens have been issued
        paused = true;
    }

    /**
     * @dev Internal function that ensures `_amount` is multiple of the granularity
     * @param _amount The quantity that wants to be checked
     */
    function requireMultiple(uint256 _amount) internal view {
        require(_amount.div(granularity).mul(granularity) == _amount);
    }

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        requireMultiple(_value);

        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        requireMultiple(_value);

        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) public returns (bool) {
        requireMultiple(_amount);

        // Return from inherited mint method
        return super.mint(_to, _amount);
    }

    /**
     * @dev Function to batch mint tokens
     * @param _to An array of addresses that will receive the minted tokens.
     * @param _amount An array with the amounts of tokens each address will get minted.
     * @return A boolean that indicates whether the operation was successful.
     */
    function batchMint(
        address[] _to,
        uint256[] _amount
    )
        hasMintPermission
        canMint
        public
        returns (bool)
    {
        require(_to.length == _amount.length);

        for (uint i = 0; i < _to.length; i++) {
            requireMultiple(_amount[i]);

            require(mint(_to[i], _amount[i]));
        }
        return true;
    }
}
