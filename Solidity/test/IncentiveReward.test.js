const { ethers } = require("hardhat")
const { expect } = require("chai")
const { time , getBigNumber, etherBalance} = require("./utilities")
const { setTime } = require("./utilities/time")
const web3 = require('web3');

describe("Stacking incentive rewards", function () {

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

        // Another court address that we will provide tokens to.
        this.courtTokenDeployed = await this.dummaryCourtToken.deploy();

        await this.farming.deployed()
        await this.lpToken.deployed();
        await this.court.deployed();
        await this.courtTokenDeployed.deployed();

        await this.farming.setLPToken(this.lpToken.address);
        await this.farming.setStakingToken(this.court.address);

        await this.farming.setCourtStake(this.courtTokenDeployed.address);

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
        const rewardsInformation = await this.farming.rewardInfo();
    })

    it("Should revert if you try to change ICourtStake if you are not owner ", async function () {
        await expect(this.farming.connect(this.bob).setCourtStake(this.courtTokenDeployed.address)).to.be.revertedWith("only contract owner can change")
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

    it("Should check the reward amount for account with single ", async function () {
        let bobRewards = await this.farming.rewards(this.bob.address);
        expect(bobRewards.incvReward).to.equal(getBigNumber(0));
        await this.farming.connect(this.bob).stake("1");
        let currentBlock = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));
        bobRewards = await this.farming.rewards(this.bob.address);
        expect(bobRewards.incvReward).to.equal(getBigNumber(1));
    })

    function getNextDate(incentiveReleaseTime) {
        const today = new Date(Number(incentiveReleaseTime + "") * 1000);
        let tomorrow = new Date(today);
        tomorrow.setDate(today.getDate() + 1);
        return tomorrow.getTime();
    }

    it("Should not give rewards because the time is not valid ", async function () {
        // Time before the time set in contract
        await setTime(1616523110);
        let currentBlock = await this.farming.blockNumber();

        let bobRewards = await this.farming.rewards(this.bob.address);
        expect(bobRewards.incvReward).to.equal(getBigNumber(0))

        let balance = await etherBalance(this.bob.address);
        await this.farming.connect(this.bob).stake("1");
        await time.advanceBlockTo(Number(currentBlock) + Number(10));

        // We will set the time of the contract of a time that we can manage to collect
        // the rewards and see weather we get them or not.
        // await setTime(1616523140);
        currentTime = await this.farming.getCurrentTime();
        // await this.farming.connect(this.bob).claimIncvReward();
        await this.farming.connect(this.bob).incvRewardClaim();
        let balanceOfCourtToken = await this.court.balanceOf(this.bob.address);
        expect(balanceOfCourtToken).to.equal(getBigNumber(0))
    })

    it("Should be able to claim incentive rewards after time is valid ", async function () {
        // We will set the time of the contract of a time that we can manage to collect
        // the rewards and see weather we get them or not.
        await setTime(1640995200);
        let currentBlock = await this.farming.blockNumber();

        let bobRewards = await this.farming.rewards(this.bob.address);
        expect(bobRewards.incvReward).to.equal(getBigNumber(0))

        // The batch count at the testing mock is 1
        let balance = await etherBalance(this.bob.address);
        await this.farming.connect(this.bob).stake("1");
        await time.advanceBlockTo(Number(currentBlock) + Number(10));

        // await this.farming.connect(this.bob).claimIncvReward();
        await this.farming.connect(this.bob).incvRewardClaim();
        let balanceOfCourtToken = await this.court.balanceOf(this.bob.address);
        expect(balanceOfCourtToken).to.equal(getBigNumber(10))
    })

    it("Should be able to claim incentive reward after another progression in the block number", async function () {
        // We will set the time of the contract of a time that we can manage to collect
        // the rewards and see weather we get them or not.
        // await setTime(1640995222);
        let cb = await this.farming.blockNumber();

        let bobRewards = await this.farming.rewards(this.bob.address);
        expect(bobRewards.incvReward).to.equal(getBigNumber(0))

        // The batch count at the testing mock is 1
        let balance = await etherBalance(this.bob.address);
        await this.farming.connect(this.bob).stake("1");
        await time.advanceBlockTo(Number(cb) + Number(1));

        // await this.farming.connect(this.bob).claimIncvReward();
        await this.farming.connect(this.bob).incvRewardClaim();
        let balanceOfCourtToken = await this.court.balanceOf(this.bob.address);
        expect(balanceOfCourtToken).to.equal(getBigNumber(1))


        cb = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(cb) + Number(1));
        balanceOfCourtToken = await this.court.balanceOf(this.bob.address);
        expect(balanceOfCourtToken).to.equal(getBigNumber(1))
    })

    it("Should be able to claim incentive reward after another progression in the block number", async function () {
        let cb = await this.farming.blockNumber();

        let bobRewards = await this.farming.rewards(this.bob.address);
        expect(bobRewards.incvReward).to.equal(getBigNumber(0))

        // The batch count at the testing mock is 1
        let balance = await etherBalance(this.bob.address);
        await this.farming.connect(this.bob).stake("1");
        await time.advanceBlockTo(Number(cb) + Number(1));

        await this.farming.connect(this.bob).incvRewardClaim();
        let balanceOfCourtToken = await this.court.balanceOf(this.bob.address);
        expect(balanceOfCourtToken).to.equal(getBigNumber(1))

        // Claim incentive calls a block propagation.
        await this.farming.connect(this.bob).incvRewardClaim();
        balanceOfCourtToken = await this.court.balanceOf(this.bob.address);
        expect(balanceOfCourtToken).to.equal(getBigNumber(2))

        await this.farming.connect(this.bob).incvRewardClaim();
        balanceOfCourtToken = await this.court.balanceOf(this.bob.address);
        expect(balanceOfCourtToken).to.equal(getBigNumber(3))
    })

    it("Should return the correct incentive reward amount", async function () {
        let cb = await this.farming.blockNumber();
        let bobRewards = await this.farming.rewards(this.bob.address);
        expect(bobRewards.incvReward).to.equal(getBigNumber(0))

        await this.farming.connect(this.bob).stake("1");
        cb = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(cb) + Number(1));

        let aboutAmount = await this.farming.getBeneficiaryInfo(this.bob.address);
        expect(aboutAmount.releasableAmount).to.equal(getBigNumber(1));
    })

    it("Should return the correct details from calling incentive information", async function () {
        let cb = await this.farming.blockNumber();

        let bobRewards = await this.farming.rewards(this.bob.address);
        expect(bobRewards.incvReward).to.equal(getBigNumber(0))

        await this.farming.connect(this.bob).stake("1");
        await time.advanceBlockTo(Number(cb) + Number(1));
        cb = await this.farming.blockNumber();
        let result = await this.farming.incvRewardInfo();
        expect(result.cBlockNumber).to.equal(cb)
        expect(result.incvRewardPerBlock).to.equal(getBigNumber(1))
    })

    it("Should return the correct next batch time for the incentive reward", async function () {
        let cb = await this.farming.blockNumber();
        let bobRewards = await this.farming.rewards(this.bob.address);
        expect(bobRewards.incvReward).to.equal(getBigNumber(0))

        await this.farming.connect(this.bob).stake("1");
        cb = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(cb) + Number(1));

        let incRealseTime = await this.farming.getIncReleaseTime();
        let nextDay = getNextDate(incRealseTime)/1000;

        let benInfo = await this.farming.getBeneficiaryInfo(this.bob.address);
        let nextTime = Number(benInfo.nextBatchTime.toString());
        expect(nextTime).to.equal(nextDay);
    })

    it("Should allow staking of the incentive rewards ", async function () {
        let bobRewards = await this.farming.rewards(this.bob.address);
        expect(bobRewards.incvReward).to.equal(getBigNumber(0));
        await this.farming.connect(this.bob).stake("1");
        let currentBlock = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(10));
        bobRewards = await this.farming.rewards(this.bob.address);
        expect(bobRewards.incvReward).to.equal(getBigNumber(10));

        await this.farming.connect(this.bob).stakeIncvRewards(getBigNumber(10));

        bobRewards = await this.farming.rewards(this.bob.address);
        expect(bobRewards.incvReward).to.equal(getBigNumber(1));
        // // We get this one from staking the incentive rewards...
        let balanceOfContract = await this.court.balanceOf(this.farming.address);
        expect(balanceOfContract).to.equal(getBigNumber(10))
    })
})
