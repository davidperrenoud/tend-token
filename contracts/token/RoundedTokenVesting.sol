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

import "../../node_modules/zeppelin-solidity/contracts/token/ERC20/TokenVesting.sol";

contract RoundedTokenVesting is TokenVesting {
    using SafeMath for uint256;

    // Minimum transferable chunk
    uint256 public granularity;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
     * of the balance will have vested.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
     * @param _start the time (as Unix time) at which point vesting starts 
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _revocable whether the vesting is revocable or not
     */
    constructor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable,
        uint256 _granularity
    )
        public
        TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable)
    {
        granularity = _granularity;
    }
    
    /**
     * @dev Calculates the amount that has already vested.
     * @param token ERC20 token which is being vested
     */
    function vestedAmount(ERC20Basic token) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released[token]);

        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start.add(duration) || revoked[token]) {
            return totalBalance;
        } else {
            uint256 notRounded = totalBalance.mul(block.timestamp.sub(start)).div(duration);

            // Round down to the nearest token chunk by using integer division: (x / 1e18) * 1e18
            uint256 rounded = notRounded.div(granularity).mul(granularity);

            return rounded;
        }
    }
}
