const { ethers } = require("hardhat")
const { expect } = require("chai")
const { time , getBigNumber} = require("./utilities")
const web3 = require('web3');

describe("Stacking", function () {

    // 1e18,1000,15e17,500,500
    const rewardPerBlockInt = 1;
    const rewardPerBlock = getBigNumber(rewardPerBlockInt);
    const rewardBlockCount = 1000;
    const incvRewardPerBlock = getBigNumber(15);
    const incvRewardBlockCount = 500;
    const incvLockTime = 500;

    let bobLatestReward;

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


        this.courtFarming = await this.CourtFarming.deploy(rewardPerBlock,
            rewardBlockCount, incvRewardPerBlock,incvRewardBlockCount,  incvLockTime );

        this.dummyLPToken = await this.dummyLPToken.deploy();
        this.dummaryCourtToken = await this.dummaryCourtToken.deploy( );

        await this.courtFarming.deployed();
        await this.dummyLPToken.deployed();
        await this.dummaryCourtToken.deployed();

        await this.courtFarming.setLPToken(this.dummyLPToken.address);
        await this.courtFarming.setStakingToken(this.dummaryCourtToken.address);

        this.dummyLPToken = await this.dummyLPToken.deployed();

        await this.dummyLPToken.transfer(this.alice.address, "1000")

        await this.dummyLPToken.transfer(this.bob.address, "230")

        await this.dummyLPToken.transfer(this.carol.address, "1000")

        await this.dummyLPToken.connect(this.bob).approve(this.courtFarming.address,
            "230", { from: this.bob.address });

        await this.dummyLPToken.connect(this.alice).approve(this.courtFarming.address,
            "1000", { from: this.alice.address });

    })

    beforeEach(async function () {
        // The contract of farming deployed.
        this.cfd = await this.courtFarming.deployed();
        // The court token deployed
        this.dct = await this.dummaryCourtToken.deployed();

        // The lp token deployed
        this.dlpt = await this.dummyLPToken.deployed();
    })

    it("should set correct state variables", async function () {
        const totalSupply = await this.courtFarming.totalSupply();
        const blocksInformation = await this.courtFarming.info();
    })

    it("Should check the reward after staking ", async function () {
        let currentBlock = await this.cfd.blockNumber();
        await this.cfd.connect(this.bob).stake("2");
        currentBlock = await this.cfd.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));
        let reward1 = await this.cfd.rewards(this.bob.address);
        expect(reward1.reward).to.equal(getBigNumber(1))
    })


    it("Should check the reward after staking of multiple accounts ", async function () {
        let currentBlock = await this.cfd.blockNumber();
        await this.cfd.connect(this.bob).stake("2");
        await this.cfd.connect(this.alice).stake("2");

        let totalSupply = await this.cfd.totalSupply();
        let balanaceOfBob = await this.cfd.balanceOf(this.bob.address);
        let balanaeOfAlice = await this.cfd.balanceOf(this.alice.address);
        let bobRatio = (balanaceOfBob/totalSupply).toPrecision(19);
        let aliceRatio = (balanaeOfAlice/totalSupply).toPrecision(19);

        currentBlock = await this.cfd.blockNumber();

        await time.advanceBlockTo(Number(currentBlock) + Number(10));

        let bobShould = bobRatio * getBigNumber(10);
        let aliceShould = aliceRatio *getBigNumber(10);

        let bobReward = await this.cfd.rewards(this.bob.address);
        let aliceReward = await this.cfd.rewards(this.alice.address);

        bobReward = (parseFloat(bobReward.reward.toString()).toPrecision(19))/1e18;
        aliceReward = (parseFloat(aliceReward.reward.toString()).toPrecision(19))/1e18;

        expect(bobReward).to.be.within(9.666666666666660, 9.6666666666666666);
        expect(aliceReward).to.be.within(3.333333333333333, 3.3333333333333335);

        currentBlock = await this.cfd.blockNumber();

        await this.cfd.connect(this.bob).unstake("2", false);

        await time.advanceBlockTo(Number(currentBlock) + Number(10));
        bobReward = await this.cfd.rewards(this.bob.address);
        aliceReward = await this.cfd.rewards(this.alice.address);

        bobReward = (parseFloat(bobReward.reward.toString()).toPrecision(19))/1e18;
        aliceReward = (parseFloat(aliceReward.reward.toString()).toPrecision(19))/1e18;
    })


    it("Should update bob reward amount after advancing one block ", async function () {
        let currentBlock = await this.cfd.blockNumber();
        let bobReward = await this.cfd.rewards(this.bob.address);
        let prevBobRewardValue = (parseFloat(bobReward.reward.toString()).toPrecision(19))/1e18;
        await time.advanceBlockTo(Number(currentBlock) + Number(1));
        bobReward = await this.cfd.rewards(this.bob.address);
        bobLatestReward = (parseFloat(bobReward.reward.toString()).toPrecision(19))/1e18;
        expect(bobLatestReward - prevBobRewardValue).to.equal(0.5);
    })

    it("Should change farming attributes and calculate farming correctly ", async function () {
        let totalSupply = await this.cfd.totalSupply();
        let balanaceOfBob = await this.cfd.balanceOf(this.bob.address);
        let bobRatio = (balanaceOfBob/totalSupply).toPrecision(19);

        let currentBlock = await this.cfd.blockNumber();
        let bobDctBalane = await this.dct.balanceOf(this.bob.address);
        let parsed = (parseFloat(bobDctBalane.toString()).toPrecision(19))/1e18;
        expect(parsed).to.equal(0);

        bobLatestReward = await this.cfd.rewards(this.bob.address);
        bobLatestReward = (parseFloat(bobLatestReward.reward.toString()).toPrecision(19))/1e18;
        currentBlock = await this.cfd.blockNumber();

        bobDctBalane = await this.dct.balanceOf(this.bob.address);
        parsed = (parseFloat(bobDctBalane.toString()).toPrecision(19))/1e18;

        await this.cfd.connect(this.bob).unstake("2", true);
        bobDctBalane = await this.dct.balanceOf(this.bob.address);
        parsed = (parseFloat(bobDctBalane.toString()).toPrecision(19))/1e18;

        expect(parsed).to.equal(Number(bobLatestReward) + Number(bobRatio));

        currentBlock = await this.cfd.blockNumber();

        await time.advanceBlockTo(Number(currentBlock) + Number(10));

        await this.cfd.connect(this.bob).unstake("0", true);
        bobDctBalane = await this.dct.balanceOf(this.bob.address);
        parsed = (parseFloat(bobDctBalane.toString()).toPrecision(19))/1e18;

        expect(parsed).to.equal(Number(bobLatestReward) + Number(bobRatio));

        bobLatestReward = await this.cfd.rewards(this.bob.address);

        bobLatestReward = (parseFloat(bobLatestReward.reward.toString()).toPrecision(19))/1e18;
        // expect(bobRewardValue - prevBobRewardValue).to.equal(1.5)
    })


    it("Stake unstake for one account ", async function () {
        let currentBlock = await this.cfd.blockNumber();
        let bobReward = await this.cfd.rewards(this.bob.address);
        let bobLatestReward = (parseFloat(bobReward.reward.toString()).toPrecision(19))/1e18;
        await this.cfd.connect(this.bob).stake("1");
        currentBlock = await this.cfd.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));
        let reward1 = await this.cfd.rewards(this.bob.address);
        bobLatestReward = (parseFloat(reward1.reward.toString()).toPrecision(19))/1e18;
        // expect(reward1.reward).to.equal(getBigNumber(1))
    })

    it("should allow stake and unstake", async function () {
        let prevBalance = await this.dlpt.balanceOf(this.bob.address);
        let putValue = 1000;
        await this.dlpt.transfer(this.bob.address, putValue);
        await this.dlpt.connect(this.bob).approve(this.cfd.address, putValue, { from: this.bob.address });

        expect(await this.dlpt.balanceOf(this.bob.address)).to.equal(putValue + Number(prevBalance))

        await this.cfd.connect(this.bob).stake(100);

        expect(await this.dlpt.balanceOf(this.bob.address)).to.equal((putValue + Number(prevBalance) - 100) )

        await this.cfd.connect(this.bob).unstake(100, true);

        expect(await this.dlpt.balanceOf(this.bob.address)).to.equal((putValue + Number(prevBalance)) )

    })
})
