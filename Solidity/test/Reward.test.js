const { ethers } = require("hardhat")
const { expect } = require("chai")
const { time , getBigNumber} = require("./utilities")
const web3 = require('web3');

describe("Stacking", function () {

    // 1e18,1000,15e17,500,500
    // const rewardPerBlockInt = 1;
    // const rewardPerBlock = getBigNumber(rewardPerBlockInt);
    // const rewardBlockCount = 1000;
    // const incvRewardPerBlock = getBigNumber(15);
    // const incvRewardBlockCount = 500;
    // const incvLockTime = 500;

    // let bobLatestReward;

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

        // this.courtFarming = await this.CourtFarming.deploy();
        // this.dummyLPToken = await this.dummyLPToken.deploy();
        // this.dummaryCourtToken = await this.dummaryCourtToken.deploy( );

        // await this.courtFarming.deployed();
        // await this.dummyLPToken.deployed();
        // await this.dummaryCourtToken.deployed();

        // await this.courtFarming.setLPToken(this.dummyLPToken.address);
        // await this.courtFarming.setStakingToken(this.dummaryCourtToken.address);
        //
        // this.dummyLPToken = await this.dummyLPToken.deployed();
        //
        // await this.dummyLPToken.transfer(this.alice.address, "1000")
        //
        // await this.dummyLPToken.transfer(this.bob.address, "230")
        //
        // await this.dummyLPToken.transfer(this.carol.address, "1000")
        //
        // await this.dummyLPToken.connect(this.bob).approve(this.courtFarming.address,
        //     "230", { from: this.bob.address });
        //
        // await this.dummyLPToken.connect(this.alice).approve(this.courtFarming.address,
        //     "1000", { from: this.alice.address });

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


        // // The contract of farming deployed.
        // this.cfd = await this.courtFarming.deployed();
        // // The court token deployed
        // this.dct = await this.dummaryCourtToken.deployed();
        //
        // // The lp token deployed
        // this.dlpt = await this.dummyLPToken.deployed();
    })

    it("should set correct state variables", async function () {
        const totalSupply = await this.farming.totalSupply();
        const blocksInformation = await this.farming.info();
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

        let totalSupply = await this.farming.totalSupply();
        let balanaceOfBob = await this.farming.balanceOf(this.bob.address);
        let balanaeOfAlice = await this.farming.balanceOf(this.alice.address);

        let bobRatio = (balanaceOfBob/totalSupply).toPrecision(19);
        let aliceRatio = (balanaeOfAlice/totalSupply).toPrecision(19);

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

        let totalSupply = await this.farming.totalSupply();
        let balanaceOfBob = await this.farming.balanceOf(this.bob.address);
        let bobRatio = (balanaceOfBob/totalSupply).toPrecision(19);

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


        // currentBlock = await this.farming.blockNumber();
        //
        // await time.advanceBlockTo(Number(currentBlock) + Number(10));
        //
        // await this.farming.connect(this.bob).unstake("0", true);
        // bobDctBalane = await this.court.balanceOf(this.bob.address);
        // parsed = (parseFloat(bobDctBalane.toString()).toPrecision(19))/1e18;
        //
        // expect(parsed).to.equal(Number(bobLatestReward) + Number(bobRatio));
        //
        // bobLatestReward = await this.farming.rewards(this.bob.address);
        //
        // bobLatestReward = (parseFloat(bobLatestReward.reward.toString()).toPrecision(19))/1e18;
        // expect(bobRewardValue - prevBobRewardValue).to.equal(1.5)
    })


    it("Stake unstake for one account ", async function () {
        let currentBlock = await this.farming.blockNumber();
        let bobReward = await this.farming.rewards(this.bob.address);
        let bobLatestReward = (parseFloat(bobReward.reward.toString()).toPrecision(19))/1e18;
        await this.farming.connect(this.bob).stake("1");
        currentBlock = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));
        let reward1 = await this.farming.rewards(this.bob.address);
        bobLatestReward = (parseFloat(reward1.reward.toString()).toPrecision(19))/1e18;
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
})
