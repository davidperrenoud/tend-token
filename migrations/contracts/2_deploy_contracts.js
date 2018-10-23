/**
 * Migration script for the token
 */
const cnf             = require('../../token.cnf.json');
const TendToken       = artifacts.require('./token/TendToken.sol');
const TendTokenVested = artifacts.require('./token/TendTokenVested.sol');

module.exports = function (deployer, network, accounts) {
    if (network === 'rinkeby' || network === 'mainnet') {
        console.log('Truffle migration is for local dev environment only!');
        console.log('For TestNet / MeinNet deployment, please use the provided NPM run scripts');
        process.exit(1);
    }

    deployer.deploy(TendToken);
    deployer.deploy(TendTokenVested);
};
