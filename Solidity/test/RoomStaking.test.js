const { ethers } = require("hardhat")
const { expect } = require("chai")
const { time , getBigNumber} = require("./utilities")

describe("RoomStaking", function () {

    const rewardPerBlockInt = 1;
    const rewardPerBlock = getBigNumber(rewardPerBlockInt);
    const rewardBlockCount = 1000;

    before(async function () {
        this.RoomStaking = await ethers.getContractFactory("RoomStakingMock")
        this.roomToken = await ethers.getContractFactory("RoomTokenMock");
        this.signers = await ethers.getSigners()
        this.alice = this.signers[0]
        this.bob = this.signers[1]
        this.carol = this.signers[2]
    })

    beforeEach(async function () {
        this.staking = await this.RoomStaking.deploy(rewardPerBlock, rewardBlockCount, this.bob.address)
        await this.staking.deployed()

        this.room = await this.roomToken.deploy()
        await this.room.deployed()

        this.staking.setRoomTokenAddress(this.room.address);

        //sending some room tokens to the accounts...
        await this.room.transfer(this.alice.address, "1000")
        await this.room.transfer(this.bob.address, getBigNumber(1000))
        await this.room.transfer(this.carol.address, getBigNumber(1000))

        await this.room.connect(this.bob).approve(this.staking.address,
            getBigNumber(1000), { from: this.bob.address });

        await this.room.connect(this.alice).approve(this.staking.address,
            getBigNumber(1000), { from: this.alice.address });

        await this.room.connect(this.carol).approve(this.staking.address,
            getBigNumber(1000), { from: this.carol.address });
    })

    it("Should allow staking from accounts and check supply decrease after staking ", async function () {
        let currentBlock = await this.staking.blockNumber();
        let bobBalance = await this.room.balanceOf(this.bob.address);
        expect(bobBalance).to.equal(getBigNumber(1000));

        await this.staking.connect(this.bob).stake(getBigNumber(1));
        bobBalance = await this.room.balanceOf(this.bob.address);
        expect(bobBalance).to.equal(getBigNumber(999));
    })

    it("Should stake with the amount of steps because we have only one accout staking ", async function () {
        await this.staking.connect(this.bob).stake(getBigNumber(1));
        let currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(10));
        let reward = await this.staking.rewards(this.bob.address);
        expect(reward).to.equal(getBigNumber(10));
    })


    it("Should check stake amount for multiple accounts ", async function () {
        let currentBlock = await this.staking.blockNumber();
        await this.staking.connect(this.bob).stake(getBigNumber(1));
        await this.staking.connect(this.carol).stake(getBigNumber(1));
        // This results in an award of one because we stepped one block.
        let bobReward = await this.staking.rewards(this.bob.address);
        expect(bobReward).to.equal(getBigNumber(1));

        currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(10));
        bobReward = await this.staking.rewards(this.bob.address);
        let carolReward = await this.staking.rewards(this.carol.address);
        expect(bobReward).to.equal(getBigNumber(6));
        expect(carolReward).to.equal(getBigNumber(5));
    })

    it("Should stake and unstake and check corrent amounts ! ", async function () {
        let currentBlock = await this.staking.blockNumber();
        await this.staking.connect(this.bob).stake(getBigNumber(1));
        await this.staking.connect(this.carol).stake(getBigNumber(1));
        // This results in an award of one because we stepped one block.
        let bobReward = await this.staking.rewards(this.bob.address);
        expect(bobReward).to.equal(getBigNumber(1));

        currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(10));
        bobReward = await this.staking.rewards(this.bob.address);
        let carolReward = await this.staking.rewards(this.carol.address);
        expect(bobReward).to.equal(getBigNumber(6));
        expect(carolReward).to.equal(getBigNumber(5));

        // at this point bob reward should be 0.5 token per block
        await this.staking.connect(this.bob).unstake(getBigNumber(1), false);
        currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));

        bobReward = await this.staking.rewards(this.bob.address);
        expect(bobReward).to.equal(getBigNumber(65, 17));

        currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));

        // When bob unstaked then carol should have 1 per block as a reward...
        carolReward = await this.staking.rewards(this.carol.address);
        expect(carolReward).to.equal(getBigNumber(75, 17));
    })
})
