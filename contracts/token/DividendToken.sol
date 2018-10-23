/**
 * @title Dividend contract
 *
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

import "../../node_modules/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "../../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract DividendToken is StandardToken, Ownable {
    using SafeMath for uint256;

    // time before dividendEndTime during which dividend cannot be claimed by token holders
    // instead the unclaimed dividend can be claimed by treasury in that time span
    uint256 public claimTimeout = 20 days;

    uint256 public dividendCycleTime = 350 days;

    uint256 public currentDividend;

    mapping(address => uint256) unclaimedDividend;

    // tracks when the dividend balance has been updated last time
    mapping(address => uint256) public lastUpdate;

    uint256 public lastDividendIncreaseDate;

    // allow payment of dividend only by special treasury account (treasury can be set and altered by owner,
    // multiple treasurer accounts are possible
    mapping(address => bool) public isTreasurer;

    uint256 public dividendEndTime = 0;

    event Payin(address _owner, uint256 _value, uint256 _endTime);

    event Payout(address _tokenHolder, uint256 _value);

    event Reclaimed(uint256 remainingBalance, uint256 _endTime, uint256 _now);

    event ChangedTreasurer(address treasurer, bool active);

    /**
     * @dev Deploy the DividendToken contract and set the owner of the contract
     */
    constructor() public {
        isTreasurer[owner] = true;
    }

    /**
     * @dev Request payout dividend (claim) (requested by tokenHolder -> pull)
     * dividends that have not been claimed within 330 days expire and cannot be claimed anymore by the token holder.
     */
    function claimDividend() public returns (bool) {
        // unclaimed dividend fractions should expire after 330 days and the owner can reclaim that fraction
        require(dividendEndTime > 0);
        require(dividendEndTime.sub(claimTimeout) > block.timestamp);

        updateDividend(msg.sender);

        uint256 payment = unclaimedDividend[msg.sender];
        unclaimedDividend[msg.sender] = 0;

        msg.sender.transfer(payment);

        // Trigger payout event
        emit Payout(msg.sender, payment);

        return true;
    }

    /**
     * @dev Transfer dividend (fraction) to new token holder
     * @param _from address The address of the old token holder
     * @param _to address The address of the new token holder
     * @param _value uint256 Number of tokens to transfer
     */
    function transferDividend(address _from, address _to, uint256 _value) internal {
        updateDividend(_from);
        updateDividend(_to);

        uint256 transAmount = unclaimedDividend[_from].mul(_value).div(balanceOf(_from));

        unclaimedDividend[_from] = unclaimedDividend[_from].sub(transAmount);
        unclaimedDividend[_to] = unclaimedDividend[_to].add(transAmount);
    }

    /**
     * @dev Update the dividend of hodler
     * @param _hodler address The Address of the hodler
     */
    function updateDividend(address _hodler) internal {
        // last update in previous period -> reset claimable dividend
        if (lastUpdate[_hodler] < lastDividendIncreaseDate) {
            unclaimedDividend[_hodler] = calcDividend(_hodler, totalSupply_);
            lastUpdate[_hodler] = block.timestamp;
        }
    }

    /**
     * @dev Get claimable dividend for the hodler
     * @param _hodler address The Address of the hodler
     */
    function getClaimableDividend(address _hodler) public constant returns (uint256 claimableDividend) {
        if (lastUpdate[_hodler] < lastDividendIncreaseDate) {
            return calcDividend(_hodler, totalSupply_);
        } else {
            return (unclaimedDividend[_hodler]);
        }
    }

    /**
     * @dev Overrides transfer method from BasicToken
     * transfer token for a specified address
     * @param _to address The address to transfer to.
     * @param _value uint256 The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        transferDividend(msg.sender, _to, _value);

        // Return from inherited transfer method
        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // Prevent dividend to be claimed twice
        transferDividend(_from, _to, _value);

        // Return from inherited transferFrom method
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Set / alter treasurer "account". This can be done from owner only
     * @param _treasurer address Address of the treasurer to create/alter
     * @param _active bool Flag that shows if the treasurer account is active
     */
    function setTreasurer(address _treasurer, bool _active) public onlyOwner {
        isTreasurer[_treasurer] = _active;
        emit ChangedTreasurer(_treasurer, _active);
    }

    /**
     * @dev Request unclaimed ETH, payback to beneficiary (owner) wallet
     * dividend payment is possible every 330 days at the earliest - can be later, this allows for some flexibility,
     * e.g. board meeting had to happen a bit earlier this year than previous year.
     */
    function requestUnclaimed() public onlyOwner {
        // Send remaining ETH to beneficiary (back to owner) if dividend round is over
        require(block.timestamp >= dividendEndTime.sub(claimTimeout));

        msg.sender.transfer(address(this).balance);

        emit Reclaimed(address(this).balance, dividendEndTime, block.timestamp);
    }

    /**
     * @dev ETH Payin for Treasurer
     * Only owner or treasurer can do a payin for all token holder.
     * Owner / treasurer can also increase dividend by calling fallback function multiple times.
     */
    function() public payable {
        require(isTreasurer[msg.sender]);
        require(dividendEndTime < block.timestamp);

        // pay back unclaimed dividend that might not have been claimed by owner yet
        if (address(this).balance > msg.value) {
            uint256 payout = address(this).balance.sub(msg.value);
            owner.transfer(payout);
            emit Reclaimed(payout, dividendEndTime, block.timestamp);
        }

        currentDividend = address(this).balance;

        // No active dividend cycle found, initialize new round
        dividendEndTime = block.timestamp.add(dividendCycleTime);

        // Trigger payin event
        emit Payin(msg.sender, msg.value, dividendEndTime);

        lastDividendIncreaseDate = block.timestamp;
    }

    /**
     * @dev calculate the dividend
     * @param _hodler address
     * @param _totalSupply uint256
     */
    function calcDividend(address _hodler, uint256 _totalSupply) public view returns(uint256) {
        return (currentDividend.mul(balanceOf(_hodler))).div(_totalSupply);
    }
}
