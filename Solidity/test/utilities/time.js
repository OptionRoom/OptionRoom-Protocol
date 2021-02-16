const {
    ethers: { BigNumber },
} = require("hardhat")
const web3 = require('web3');

async function advanceBlockTo(blockNumber) {
    for (let i = await ethers.provider.getBlockNumber(); i < blockNumber; i++) {
        await ethers.provider.send("evm_mine", [])
    }
}

async function increaseTime(seconds) {
    await ethers.provider.send("evm_increaseTime", [seconds])
    await ethers.provider.send("evm_mine")
}

async function setTime(seconds) {
    // await ethers.provider.send( 'evm_setTime', [1615581732]);
    // await ethers.provider.send("evm_setTime", [seconds])
    await ethers.provider.send("evm_setNextBlockTimestamp", [seconds])
    return ethers.provider.send("evm_mine") // this one will have 2021-07-01 12:00 AM as its timestamp, no matter what the previous block has
}

async function freezeTime(seconds) {
    await ethers.provider.send('evm_freezeTime', [seconds]);
    return ethers.provider.send( 'evm_mine');
}

const duration = {
    seconds: function (val) {
        return new BigNumber(val)
    },
    minutes: function (val) {
        return new BigNumber(val).mul(this.seconds("60"))
    },
    hours: function (val) {
        return new BigNumber(val).mul(this.minutes("60"))
    },
    days: function (val) {
        return new BigNumber(val).mul(this.hours("24"))
    },
    weeks: function (val) {
        return new BigNumber(val).mul(this.days("7"))
    },
    years: function (val) {
        return new BigNumber(val).mul(this.days("365"))
    },
}

module.exports = {
    advanceBlockTo,
    duration,
    increaseTime,
    setTime,
    freezeTime,
}
