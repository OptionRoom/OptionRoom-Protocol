const { ethers } = require("hardhat")
const { expect } = require("chai")
const { time , getBigNumber} = require("./utilities")

describe("RoomLPStaking", function () {

    const rewardPerBlockInt = 1;
    const rewardPerBlock = getBigNumber(rewardPerBlockInt);
    const rewardBlockCount = 1000;

    before(async function () {
        this.RoomStaking = await ethers.getContractFactory("RoomStakingMock");
        this.RoomLpToken = await ethers.getContractFactory("LPTokenMock");
        this.roomToken = await ethers.getContractFactory("RoomTokenMock");
        this.signers = await ethers.getSigners()
        this.alice = this.signers[0]
        this.bob = this.signers[1]
        this.carol = this.signers[2]
        this.dev = this.signers[4]
    })

    beforeEach(async function () {
        this.staking = await this.RoomStaking.deploy(rewardPerBlock, rewardBlockCount, this.dev.address)
        await this.staking.deployed()

        this.lpToken = await this.RoomLpToken.deploy()
        await this.lpToken.deployed()

        this.room = await this.roomToken.deploy()
        await this.room.deployed()

        this.staking.setLpTokenAddress(this.lpToken.address);
        this.staking.setRoomTokenAddress(this.room.address);

        // Putting alice as the wallet...
        await this.room.transfer(this.dev.address, getBigNumber(1000000))
        await this.room.connect(this.dev).approve(this.staking.address,
            getBigNumber(1000000), { from: this.dev.address });

        //sending some room tokens to the accounts...
        await this.lpToken.transfer(this.alice.address, "1000")
        await this.lpToken.transfer(this.bob.address, getBigNumber(1000))
        await this.lpToken.transfer(this.carol.address, getBigNumber(1000))

        await this.lpToken.connect(this.bob).approve(this.staking.address,
            getBigNumber(1000), { from: this.bob.address });

        await this.lpToken.connect(this.alice).approve(this.staking.address,
            getBigNumber(1000), { from: this.alice.address });

        await this.lpToken.connect(this.carol).approve(this.staking.address,
            getBigNumber(1000), { from: this.carol.address });
    })

    it("Should allow staking from accounts", async function () {
        let currentBlock = await this.staking.blockNumber();
        let bobBalance = await this.lpToken.balanceOf(this.bob.address);
        expect(bobBalance).to.equal(getBigNumber(1000));

        await this.staking.connect(this.bob).stake(getBigNumber(1));
        bobBalance = await this.lpToken.balanceOf(this.bob.address);
        expect(bobBalance).to.equal(getBigNumber(999));
    })

    it("Should be able to stake and check rewards for one account ", async function () {
        await this.staking.connect(this.bob).stake(getBigNumber(1));
        let currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(10));
        let reward = await this.staking.rewards(this.bob.address);
        expect(reward).to.equal(getBigNumber(10));
    })

    it("Should be able to stake and check rewards for multiple accounts ", async function () {
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

    it("Should check balance of LP token once unstake ", async function () {
        await this.staking.connect(this.bob).stake(getBigNumber(1));
        let currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(10));
        let reward = await this.staking.rewards(this.bob.address);
        expect(reward).to.equal(getBigNumber(10));


        let bobLPBalanace = await this.lpToken.connect(this.bob).balanceOf(this.bob.address);
        expect(bobLPBalanace).to.equal(getBigNumber(999));

        // Unstake, true or false does not matter here.
        await this.staking.connect(this.bob).unstake(getBigNumber(1), true);
        currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));

        bobLPBalanace = await this.lpToken.connect(this.bob).balanceOf(this.bob.address);
        expect(bobLPBalanace).to.equal(getBigNumber(1000));
    })

    it("Should revert if you try to unstake while you do not have LP tokens ", async function () {
        await expect(this.staking.connect(this.bob).unstake(getBigNumber(1), true)).to.be.revertedWith("subtraction overflow")
    })

    it("Should check balance of LP token once unstake ", async function () {
        await this.staking.connect(this.bob).stake(getBigNumber(1));
        let currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(10));
        let reward = await this.staking.rewards(this.bob.address);
        expect(reward).to.equal(getBigNumber(10));

        let bobLPBalanace = await this.lpToken.connect(this.bob).balanceOf(this.bob.address);
        expect(bobLPBalanace).to.equal(getBigNumber(999));

        // Unstake, true or false does not matter here.
        await this.staking.connect(this.bob).unstake(getBigNumber(1), true);

        let devRoomWalletBalanace = await this.room.balanceOf(this.bob.address);
        expect(devRoomWalletBalanace).to.equal(getBigNumber(11));
    })


    it("Should check balance of LP token once unstake ", async function () {
        await this.staking.connect(this.bob).stake(getBigNumber(1));
        let currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(10));
        let reward = await this.staking.rewards(this.bob.address);
        expect(reward).to.equal(getBigNumber(10));

        let bobLPBalanace = await this.lpToken.connect(this.bob).balanceOf(this.bob.address);
        expect(bobLPBalanace).to.equal(getBigNumber(999));

        // Unstake, true or false does not matter here.
        await this.staking.connect(this.bob).claimReward();

        let devRoomWalletBalanace = await this.room.balanceOf(this.bob.address);
        expect(devRoomWalletBalanace).to.equal(getBigNumber(11));
    })


})
