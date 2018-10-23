const sha3 = require('web3-utils').sha3;
const fs = require('fs');
const assert = require('assert');

// Valid hashes using Keccak-256

const contracts = {
    MintableToken : fs.readFileSync('node_modules/zeppelin-solidity/contracts/token/ERC20/MintableToken.sol'),
    PausableToken : fs.readFileSync('node_modules/zeppelin-solidity/contracts/token/ERC20/PausableToken.sol'),
    StandardToken : fs.readFileSync('node_modules/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol'),
    Pausable      : fs.readFileSync('node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol'),
    Ownable       : fs.readFileSync('node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol'),
    ERC20         : fs.readFileSync('node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol'),
    BasicToken    : fs.readFileSync('node_modules/zeppelin-solidity/contracts/token/ERC20/BasicToken.sol'),
    ERC20Basic    : fs.readFileSync('node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol'),
    SafeMath      : fs.readFileSync('node_modules/zeppelin-solidity/contracts/math/SafeMath.sol')
};

const hashes = {
    MintableToken : '0x7184403681dfe14804bd60f4f5aef5e40f79cccc162ba29581602f8edb54853d',
    PausableToken : '0xd94abec1ad66a5167113d79e0aea2ae725cf3d34f8d72b70ea2115199c715391',
    StandardToken : '0xf4ae4ed0fd71f15329df75d165c68afc24385262abbf323f1396ee681f72073d',
    Pausable      : '0x9cba4eb7059b38a00d34429f77f279257609b42c2800612cd5521914c364a492',
    Ownable       : '0x2c92ef64d25ddba75a96b518ab3ad5211c4edab898ac2a693c300274ccd0c675',
    ERC20         : '0xd48f887d15d0411901fc331e74a25d7afa63d89a1257e8e3f43ce1b1e8f4a1e3',
    BasicToken    : '0xa1a882b859b5ceac4a879b4820bf5c2eeeee823b563da42abac5ef119fd6e39e',
    ERC20Basic    : '0xa36ddb4cd5f04f0f5b7f344819267dd5500467d58949dd012a85876233c9314e',
    SafeMath      : '0x6f859ac66b474844c08916cd628b116978fb0f211489a5f45b1fb4a2f7db56b1'
};

Object.keys(contracts).forEach((key) => {
    try {
        assert.equal(sha3(contracts[key]), hashes[key], 'Hash mismatch: ' + key);
    } catch (error) {
        console.log(error.message + ' - Zeppelin Framework');
        console.log('New Hash: ' + sha3(contracts[key]));
    }
});
