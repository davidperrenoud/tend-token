/**
 * Test for TokenCrowdsale
 *
 * @author Validity Labs AG <info@validitylabs.org>
 */

import {expectThrow, waitNDays, getEvents, BigNumber, cnf, increaseTimeTo} from './helpers/tools';
import {logger as log} from '../../tools/logger';

const TendTokenVested = artifacts.require('./TendTokenVested');
const TokenVesting    = artifacts.require('./TokenVesting');

const should = require('chai') // eslint-disable-line
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

// const MAX_TOKEN_CAP         = new BigNumber(13e6 * 1e18);
const DEVELOPMENT_TEAM_CAP  = new BigNumber(2e6 * 1e18);
// const CROWDSALE_TOKEN_CAP   = new BigNumber(95e5 * 1e18);
// const DISCOUNT_TOKEN_AMOUNT = new BigNumber(3e6 * 1e18);

/**
 * TendTokenVesting contract
 */
contract('TendTokenVested', (accounts) => {
    const owner             = accounts[0];
    const activeManager     = accounts[1];
    const inactiveManager   = accounts[2];
    const activeInvestor1   = accounts[3];
    const activeInvestor2   = accounts[4];
    const inactiveInvestor1 = accounts[5];
    const wallet            = accounts[6];

    // added wallets
    const teamWallet    = accounts[7];
    const companyWallet = accounts[8];
    const underwriter   = accounts[9];

    const coinbaseWallet    = '0xfc2f61eda5777de5626320416f117d10aac149a0';
    const coinbaseWallet2   = '0xfd7c5cb66af6bf21023aa559622a5a87b0ade124';

    // Provide tendTokenVestedInstance for every test case
    let tendTokenVestedInstance;

    beforeEach(async () => {
        tendTokenVestedInstance = await TendTokenVested.deployed();
    });

    /**
     * [ Pre contribution period ]
     */

    it('should instantiate the vested token correctly', async () => {
        console.log('[ Year 0 ]'.yellow);

        const isOwnerAccountZero    = await tendTokenVestedInstance.owner() === owner;

        assert.isTrue(isOwnerAccountZero, 'Owner is not the first account: ' + tendTokenVestedInstance.owner());
    });

    it('should fail, because we try to mint DevelopmentTeamTokens with zero amount', async () => {
        await expectThrow(tendTokenVestedInstance.mintDevelopmentTeamTokens(
            activeManager,
            0,
            {from: owner}
        ));
    });

    it('should fail, because we try to mint DevelopmentTeamTokens with value higher than cap', async () => {
        await expectThrow(tendTokenVestedInstance.mintDevelopmentTeamTokens(
            activeManager,
            DEVELOPMENT_TEAM_CAP.add(1),
            {from: owner}
        ));
    });

    it('should mint 20e18 DevelopmentTeam Tokens', async () => {
        const companyWalletBalance1 = await tendTokenVestedInstance.balanceOf(companyWallet);
        let numVestingWallets = await tendTokenVestedInstance.getVestingWalletLength();
        assert.equal(numVestingWallets, 0);

        await tendTokenVestedInstance.mintDevelopmentTeamTokens(
            companyWallet,
            20e18,
            {from: owner}
        );

        numVestingWallets = await tendTokenVestedInstance.getVestingWalletLength();
        assert.equal(numVestingWallets, 1);

        const vestingWallet0 = await tendTokenVestedInstance.vestingWallets(0);
        const balanceVestingWallet0 = await tendTokenVestedInstance.balanceOf(vestingWallet0);

        balanceVestingWallet0.should.be.bignumber.equal(20e18);

        const companyWalletBalance2 = await tendTokenVestedInstance.balanceOf(companyWallet);

        companyWalletBalance1.should.be.bignumber.equal(companyWalletBalance2);
    });

    it('should transfer ownership to activeInvestor1 and back to owner', async () => {
        const ownerBefore = await tendTokenVestedInstance.owner();
        assert.equal(ownerBefore, owner);

        await tendTokenVestedInstance.transferOwnership(activeInvestor1, {from: owner});

        let ownerAfter = await tendTokenVestedInstance.owner();
        assert.equal(ownerAfter, activeInvestor1);

        await tendTokenVestedInstance.transferOwnership(owner, {from: activeInvestor1});

        ownerAfter = await tendTokenVestedInstance.owner();
        assert.equal(ownerAfter, owner);
    });

    it('should fail, because we try to release the vested tokens before the cliff', async () => {
        const vestingWallet0 = await tendTokenVestedInstance.vestingWallets(0);
        const vestingInstance = await TokenVesting.at(vestingWallet0);

        await expectThrow(vestingInstance.release(tendTokenVestedInstance.address));
    });

    it('should unpause TEND token correctly', async () => {
        console.log('[ Year 1 ]'.yellow);

        await tendTokenVestedInstance.unpause({from: owner});
        const paused = await tendTokenVestedInstance.paused();

        assert.isFalse(paused);
    });

    it('should release a third of the vested tokens after 1 year', async () => {
        await waitNDays(365);

        const numVestingWallets = await tendTokenVestedInstance.getVestingWalletLength();
        assert.equal(numVestingWallets, 1);

        const vestingWallet0 = await tendTokenVestedInstance.vestingWallets(0);
        const vestingInstance = await TokenVesting.at(vestingWallet0);
        const balanceVestingWallet0Before = await tendTokenVestedInstance.balanceOf(vestingWallet0);
        const balanceCompanyWalletBefore = await tendTokenVestedInstance.balanceOf(companyWallet);

        await vestingInstance.release(tendTokenVestedInstance.address);

        const balanceVestingWallet0After = await tendTokenVestedInstance.balanceOf(vestingWallet0);
        const balanceCompanyWalletAfter = await tendTokenVestedInstance.balanceOf(companyWallet);

        balanceCompanyWalletBefore.should.be.bignumber.equal(0e18);
        balanceVestingWallet0Before.should.be.bignumber.equal(20e18);
        balanceCompanyWalletAfter.should.be.bignumber.equal(6e18);
        balanceVestingWallet0After.should.be.bignumber.equal(14e18);
    });

    it('should release the rest of the vested tokens after 3 years', async () => {
        console.log('[ Year 3 ]'.yellow);
        await waitNDays(2 * 365);

        const numVestingWallets = await tendTokenVestedInstance.getVestingWalletLength();
        assert.equal(numVestingWallets, 1);

        const vestingWallet0 = await tendTokenVestedInstance.vestingWallets(0);
        const vestingInstance = await TokenVesting.at(vestingWallet0);
        const balanceVestingWallet0Before = await tendTokenVestedInstance.balanceOf(vestingWallet0);
        const balanceCompanyWalletBefore = await tendTokenVestedInstance.balanceOf(companyWallet);

        await vestingInstance.release(tendTokenVestedInstance.address);

        const balanceVestingWallet0After = await tendTokenVestedInstance.balanceOf(vestingWallet0);
        const balanceCompanyWalletAfter = await tendTokenVestedInstance.balanceOf(companyWallet);

        balanceCompanyWalletBefore.should.be.bignumber.equal(6e18);
        balanceVestingWallet0Before.should.be.bignumber.equal(14e18);
        balanceCompanyWalletAfter.should.be.bignumber.equal(20e18);
        balanceVestingWallet0After.should.be.bignumber.equal(0e18);
    });
});
