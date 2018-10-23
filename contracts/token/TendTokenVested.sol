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

import "../../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./TendToken.sol";
import "./RoundedTokenVesting.sol";

contract TendTokenVested is TendToken {
    using SafeMath for uint256;

    /*** CONSTANTS ***/
    uint256 public constant DEVELOPMENT_TEAM_CAP = 2e6 * 1e18;  // 2 million * 1e18

    uint256 public constant VESTING_CLIFF = 0 days;
    uint256 public constant VESTING_DURATION = 3 * 365 days;

    uint256 public developmentTeamTokensMinted;

    // for convenience we store vesting wallets
    address[] public vestingWallets;

    modifier onlyNoneZero(address _to, uint256 _amount) {
        require(_to != address(0));
        require(_amount > 0);
        _;
    }

    /**
     * @dev allows contract owner to mint team tokens per DEVELOPMENT_TEAM_CAP and transfer to the development team's wallet (yes vesting)
     * @param _to address for beneficiary
     * @param _tokens uint256 token amount to mint
     */
    function mintDevelopmentTeamTokens(address _to, uint256 _tokens) public onlyOwner onlyNoneZero(_to, _tokens) returns (bool) {
        requireMultiple(_tokens);
        require(developmentTeamTokensMinted.add(_tokens) <= DEVELOPMENT_TEAM_CAP);

        developmentTeamTokensMinted = developmentTeamTokensMinted.add(_tokens);
        RoundedTokenVesting newVault = new RoundedTokenVesting(_to, block.timestamp, VESTING_CLIFF, VESTING_DURATION, false, granularity);
        vestingWallets.push(address(newVault)); // for convenience we keep them in storage so that they are easily accessible via MEW or etherscan
        return mint(address(newVault), _tokens);
    }

    /**
     * @dev returns number of elements in the vestinWallets array
     */
    function getVestingWalletLength() public view returns (uint256) {
        return vestingWallets.length;
    }
}
