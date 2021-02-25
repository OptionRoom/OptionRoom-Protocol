const { ethers } = require("hardhat")
const { expect } = require("chai")
const { time , getBigNumber} = require("./utilities")
const web3 = require('web3');

// Testing for staking the room to get court.
describe("Court/Rewards farming test", function () {

    before(async function () {
        this.signers = await ethers.getSigners()
        this.alice = this.signers[0]
        this.bob = this.signers[1]
        this.carol = this.signers[2]
        this.dev = this.signers[3]
        this.minter = this.signers[4]

        this.CourtFarming = await ethers.getContractFactory("CourtFarmingMock");
        this.dummyLPToken = await ethers.getContractFactory("LPTokenMock");
        this.dummaryCourtToken = await ethers.getContractFactory("ERC20DetailedMock");
    })

    beforeEach(async function () {
        this.farming = await this.CourtFarming.deploy();
        this.lpToken = await this.dummyLPToken.deploy();
        this.court = await this.dummaryCourtToken.deploy( );

        await this.farming.deployed()
        await this.lpToken.deployed();
        await this.court.deployed();

        await this.farming.setLPToken(this.lpToken.address);
        await this.farming.setStakingToken(this.court.address);

        await this.lpToken.transfer(this.alice.address, "1000")

        await this.lpToken.transfer(this.bob.address, "230")

        await this.lpToken.transfer(this.carol.address, "1000")

        await this.lpToken.connect(this.bob).approve(this.farming.address,
            "230", { from: this.bob.address });

        await this.lpToken.connect(this.alice).approve(this.farming.address,
            "1000", { from: this.alice.address });
    })

    it("should set correct state variables", async function () {
        const totalStaked = await this.farming.totalStaked();
        expect(totalStaked).to.equal(getBigNumber(0))
        const blocksInformation = await this.farming.rewardInfo();
    })

    it("Should revert if you try to stack more tokens than you have ", async function () {
        await expect(this.farming.connect(this.bob).stake("1001")).to.be.revertedWith("low-level call failed")
    })

    it("Should revert if you try to unstack tokens you do not have ", async function () {
        await expect(this.farming.connect(this.bob).unstake("1", false)).to.be.revertedWith("subtraction overflow")
    })

    it("Should be reverted if I try to stake more tokens that approved ", async function () {
        let bobRewards = await this.farming.rewards(this.bob.address);
        expect(bobRewards.incvReward).to.equal(getBigNumber(0));
        await expect(this.farming.connect(this.bob).stake("231")).to.be.revertedWith("low-level call failed")
    })

    it("Should check the reward after staking ", async function () {
        await this.farming.connect(this.bob).stake("2");
        let cb = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(cb) + Number(1));
        let bobReward = await this.farming.rewards(this.bob.address);
        expect(bobReward.reward).to.equal(getBigNumber(1))
    })

    it("Should check the reward after staking of multiple accounts ", async function () {
        let bsb = await this.farming.blockNumber();
        let currentBlock = await this.farming.blockNumber();
        await this.farming.connect(this.bob).stake("2");

        await this.farming.connect(this.alice).stake("2");
        let asb = await this.farming.blockNumber();

        let totalStaked = await this.farming.totalStaked();
        let balanaceOfBob = await this.farming.balanceOf(this.bob.address);
        let balanaeOfAlice = await this.farming.balanceOf(this.alice.address);

        let bobRatio = (balanaceOfBob/totalStaked).toPrecision(19);
        let aliceRatio = (balanaeOfAlice/totalStaked).toPrecision(19);

        currentBlock = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(10));

        let cb = await this.farming.blockNumber();
        let bobShould = bobRatio * (cb - bsb);
        let aliceShould = aliceRatio * ( cb - asb );

        let bobReward = await this.farming.rewards(this.bob.address);
        let aliceReward = await this.farming.rewards(this.alice.address);

        expect(bobReward.reward).to.equal(getBigNumber(bobShould));
        expect(aliceReward.reward).to.equal(getBigNumber(aliceShould));

        await this.farming.connect(this.bob).unstake("2", false);
        currentBlock = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));

        aliceReward = await this.farming.rewards(this.alice.address);

        expect(aliceReward.reward).to.equal(getBigNumber(65, 17));
    })


    it("Should update bob reward amount after advancing one block ", async function () {
        await this.farming.connect(this.bob).stake("2");
        let currentBlock = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));
        let bobReward = await this.farming.rewards(this.bob.address);
        expect(bobReward.reward).to.equal(getBigNumber(1));
    })

    it("Should change farming attributes and calculate farming correctly ", async function () {
        await this.farming.connect(this.bob).stake("2");

        let totalStaked = await this.farming.totalStaked();
        let balanaceOfBob = await this.farming.balanceOf(this.bob.address);
        let bobRatio = (balanaceOfBob/totalStaked).toPrecision(19);

        let currentBlock = await this.farming.blockNumber();
        let bobFarmingBalance = await this.farming.balanceOf(this.bob.address);
        expect(bobFarmingBalance).to.equal(2);

        currentBlock = await this.farming.blockNumber();

        bobCourtBalance = await this.court.balanceOf(this.bob.address);
        expect(bobCourtBalance).to.equal(0);

        currentBlock = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));

        await this.farming.connect(this.bob).unstake("2", true);

        bobCourtBalance = await this.court.balanceOf(this.bob.address);
        expect(bobCourtBalance).to.equal(getBigNumber(2));


        currentBlock = await this.farming.blockNumber();

        await time.advanceBlockTo(Number(currentBlock) + Number(10));

        await this.farming.connect(this.bob).unstake("0", true);
        bobDctBalane = await this.court.balanceOf(this.bob.address);
        expect(bobDctBalane).to.equal(getBigNumber(2));
    })


    it("Stake unstake for one account ", async function () {
        let currentBlock = await this.farming.blockNumber();
        let bobReward = await this.farming.rewards(this.bob.address);
        let bobLatestReward = (parseFloat(bobReward.reward.toString()).toPrecision(19))/1e18;
        await this.farming.connect(this.bob).stake("1");
        currentBlock = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));
        let reward1 = await this.farming.rewards(this.bob.address);
        // expect(reward1.reward).to.equal(getBigNumber(1))
    })

    it("should allow stake and unstake", async function () {
        let prevBalance = await this.lpToken.balanceOf(this.bob.address);
        let putValue = 1000;
        await this.lpToken.transfer(this.bob.address, putValue);
        await this.lpToken.connect(this.bob).approve(this.farming.address, putValue, { from: this.bob.address });

        expect(await this.lpToken.balanceOf(this.bob.address)).to.equal(putValue + Number(prevBalance))

        await this.farming.connect(this.bob).stake(100);

        expect(await this.lpToken.balanceOf(this.bob.address)).to.equal((putValue + Number(prevBalance) - 100) )

        await this.farming.connect(this.bob).unstake(100, true);

        expect(await this.lpToken.balanceOf(this.bob.address)).to.equal((putValue + Number(prevBalance)) )

    })

    it("Should revert because none owner is calling.", async function () {
        await expect(this.farming.connect(this.bob).changeToContractAttributes()).to.be.revertedWith("can be called by owner only")
    })

    it("Should revert because none owner is calling.", async function () {
        await this.farming.connect(this.alice).changeToContractAttributes();
    })

    it("Should return correct values staked after changing attributes.", async function () {
        await this.farming.connect(this.alice).changeToContractAttributes();

        await this.farming.connect(this.bob).stake("1");
        let cb = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(cb) + Number(5760/100));
        let bobReward = await this.farming.rewards(this.bob.address);
        expect(Number(bobReward.reward/1e18)).to.be.
            closeTo(getBigNumber(1)/1e18, 0.01);

    })
})
