const { ethers } = require("hardhat")
const { expect } = require("chai")
const { time , getBigNumber} = require("./utilities")
const web3 = require('web3');

describe("Stacking incentive rewards", function () {

    // 1e18,1000,15e17,500,500
    const rewardPerBlockInt = 1;
    const rewardPerBlock = getBigNumber(rewardPerBlockInt);
    const rewardBlockCount = 1000;
    const incvRewardPerBlock = getBigNumber(15);
    const incvRewardBlockCount = 500;
    const incvLockTime = 500; //12 March 2021 20:42:12

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

        await this.dummyLPToken.transfer(this.bob.address, "1000")

        await this.dummyLPToken.transfer(this.carol.address, "1000")

        await this.dummyLPToken.connect(this.bob).approve(this.courtFarming.address,
            "1000", { from: this.bob.address });
        await this.dummyLPToken.connect(this.alice).approve(this.courtFarming.address,
            "1000", { from: this.alice.address });

    })

    beforeEach(async function () {
        // The contract of farming deployed.
        this.cfd = await this.courtFarming.deployed();
        // The court token deployed
        this.dct = await this.dummaryCourtToken.deployed();
    })

    it("Should check the reward amount for account with single ", async function () {

        let currentBlock = await this.cfd.blockNumber();

        await this.cfd.connect(this.bob).stake("2");

        currentBlock = await this.cfd.blockNumber();

        await time.advanceBlockTo(Number(currentBlock) + Number(1));

        currentBlock = await this.cfd.blockNumber();

        let reward1 = await this.cfd.rewards(this.bob.address);
        expect(reward1.reward).to.equal(getBigNumber(1))

        currentBlock = await this.cfd.blockNumber();

        await this.cfd.changeFarmingParameters(
            getBigNumber(2, 18),
            rewardBlockCount, incvRewardPerBlock,incvRewardBlockCount,  incvLockTime
        )

        currentBlock = await this.cfd.blockNumber();

        reward1 = await this.cfd.rewards(this.bob.address);

        await time.advanceBlockTo(Number(currentBlock) + Number(1));

        currentBlock = await this.cfd.blockNumber();

        reward1 = await this.cfd.rewards(this.bob.address);
        // expect(reward1.reward).to.equal(getBigNumber(1))
    })


})
