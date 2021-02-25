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
        this.dummaryCourtToken = await ethers.getContractFactory("LimitedERC20DetailedMock");
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

    it("Should be able to mint more about then initially minted ", async function () {
        await this.farming.connect(this.bob).stake("2");
        let cb = await this.farming.blockNumber();
        await time.advanceBlockTo(Number(cb) + Number(300));
        let bobReward = await this.farming.rewards(this.bob.address);
        expect(bobReward.reward).to.equal(getBigNumber(300));

        await this.farming.connect(this.bob).unstake("2", true);
        bobReward = await this.farming.rewards(this.bob.address);
        expect(bobReward.reward).to.equal(getBigNumber(0));

        let balanceOfCourtToken = await this.court.balanceOf(this.bob.address);
        expect(balanceOfCourtToken).to.equal(getBigNumber(301))
    })
})
