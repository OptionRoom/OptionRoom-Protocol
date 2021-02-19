const {ethers} = require("hardhat")
const {expect} = require("chai")
const {time, getBigNumber} = require("./utilities")
var abi = require('ethereumjs-abi')

describe("OptionNFT", function () {

    before(async function () {
        this.NFTStake = await ethers.getContractFactory("NFTStakeMock");
        this.roomToken = await ethers.getContractFactory("NFTRoomTokenMock");
        this.nftToken = await ethers.getContractFactory("NFTTokenMock");
        this.signers = await ethers.getSigners()
        this.alice = this.signers[0]
        this.bob = this.signers[1]
        this.carol = this.signers[2]
        this.dev = this.signers[4]
    })

    beforeEach(async function () {
        this.staking = await this.NFTStake.deploy(this.dev.address)
        await this.staking.deployed()

        this.room = await this.roomToken.deploy()
        await this.room.deployed()

        this.nft = await this.nftToken.deploy()
        await this.nft.deployed()

        await this.staking.setRoomTokenAddress(this.room.address);
        await this.staking.setNFTTokenAddress(this.nft.address);
        await this.staking.assignValues();

        // Putting alice as the wallet...
        await this.room.transfer(this.dev.address, getBigNumber(1000000))
        await this.room.connect(this.dev).approve(this.staking.address,
            getBigNumber(1000000), {from: this.dev.address});

        //sending some room tokens to the accounts...
        await this.room.transfer(this.alice.address, "1000")
        await this.room.transfer(this.bob.address, getBigNumber(50000))
        await this.room.transfer(this.carol.address, getBigNumber(1000))

        await this.room.connect(this.bob).approve(this.staking.address,
            getBigNumber(50000), {from: this.bob.address});

        await this.room.connect(this.alice).approve(this.staking.address,
            getBigNumber(1000), {from: this.alice.address});

        await this.room.connect(this.carol).approve(this.staking.address,
            getBigNumber(1000), {from: this.carol.address});

        await this.nft.connect(this.alice).setApprovalForAll(this.staking.address, true);
        await this.nft.connect(this.bob).setApprovalForAll(this.staking.address, true);
        await this.nft.connect(this.carol).setApprovalForAll(this.staking.address, true);

        // Provide some nft for the account
        await this.nft.mintForAddress(this.bob.address);
        await this.nft.mintForAddress(this.carol.address);
    })

    it("Should check balance of account after staking", async function () {
        // let currentBlock = await this.staking.blockNumber();
        let bobBalance = await this.nft.balanceOf(this.bob.address, 0);
        expect(bobBalance).to.equal(1000);

        await this.staking.connect(this.bob).stake(0, getBigNumber(1));
        bobBalance = await this.nft.balanceOf(this.bob.address, 0);
        expect(bobBalance).to.equal(999);
    })

    it("Should check balance of contract after staking", async function () {
        await this.staking.connect(this.bob).stake(0, getBigNumber(1));
        let stakingBalance = await this.nft.balanceOf(this.staking.address, 0);
        expect(stakingBalance).to.equal(1);
    })

    it("Should check room balance after staking", async function () {
        // let currentBlock = await this.staking.blockNumber();
        let bobRoomBalance = await this.room.balanceOf(this.bob.address);
        expect(bobRoomBalance).to.equal(getBigNumber(50000));

        await this.staking.connect(this.bob).stake(0, getBigNumber(1));
        bobRoomBalance = await this.room.balanceOf(this.bob.address);
        expect(bobRoomBalance).to.equal(getBigNumber(49999));
    })

    it("Should be able to stake and check rewards for one account ", async function () {
        await this.staking.connect(this.bob).stake(0, getBigNumber(1));
        let currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(10));

        let reward = await this.staking.rewards(0, this.bob.address);
        expect(reward).to.equal(getBigNumber(10));
    })

    it("Should be able to stake multiple accounts ", async function () {
        await this.staking.connect(this.bob).stake(0, getBigNumber(1));
        await this.staking.connect(this.carol).stake(0, getBigNumber(1));
        let currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(10));

        let bobReward = await this.staking.rewards(0, this.bob.address);
        let carolReward = await this.staking.rewards(0, this.carol.address);

        expect(bobReward).to.equal(getBigNumber(6));
        expect(carolReward).to.equal(getBigNumber(5));
    })

    it("Should allow stake and unstake and give the correct results ", async function () {
        await this.staking.connect(this.bob).stake(0, getBigNumber(1));
        let currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(10));
        let reward = await this.staking.rewards(0, this.bob.address);
        expect(reward).to.equal(getBigNumber(10));


        let bobLPBalanace = await this.room.connect(this.bob).balanceOf(this.bob.address);
        expect(bobLPBalanace).to.equal(getBigNumber(49999));

        // Unstake, true or false does not matter here.
        await this.staking.connect(this.bob).unstake(0, getBigNumber(1), true);
        currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));

        bobLPBalanace = await this.room.connect(this.bob).balanceOf(this.bob.address);
        expect(bobLPBalanace).to.equal(getBigNumber(50011));
    })

    it("Should allow exiting a pool ", async function () {
        await this.staking.connect(this.bob).stake(0, getBigNumber(1));
        let currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(10));
        let reward = await this.staking.rewards(0, this.bob.address);
        expect(reward).to.equal(getBigNumber(10));


        let bobLPBalanace = await this.room.connect(this.bob).balanceOf(this.bob.address);
        expect(bobLPBalanace).to.equal(getBigNumber(49999));

        // Exit the pool
        await this.staking.connect(this.bob).exit(0);

        bobLPBalanace = await this.room.connect(this.bob).balanceOf(this.bob.address);
        expect(bobLPBalanace).to.equal(getBigNumber(50011));

        // Because we have got 1000 piece at the NFTTokenMock for this account.
        let bobNFTBalance = await this.nft.balanceOf(this.bob.address, 0);
        expect(bobNFTBalance).to.equal(1000);
    })

    it("Should revert if you try to unstake while you do not have anything staked ", async function () {
        await expect(this.staking.connect(this.bob).unstake(0, getBigNumber(1), true)).to.be.revertedWith("subtraction overflow")
    })

    it("Should check values of the org contract values", async function () {
        await this.staking.connect(this.bob).assignOrgValues();
        let rewardValue = await this.staking.connect(this.bob).getRewardValueForPool1();

        await this.staking.connect(this.bob).stake(0, getBigNumber(1));
        let currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));

        let reward = await this.staking.rewards(0, this.bob.address);
        reward = (parseFloat(reward.toString()).toPrecision(19))/1e18;
        expect(reward).to.equal(0.024051890432098762);
    })

    it("Should check values of the org contract values", async function () {
        await this.staking.connect(this.bob).assignOrgValues();
        let rewardValue = await this.staking.connect(this.bob).getRewardValueForPool1();

        await this.staking.connect(this.bob).stake(0, getBigNumber(1));
        let currentBlock = await this.staking.blockNumber();
        await time.advanceBlockTo(Number(currentBlock) + Number(1));

        let reward = await this.staking.rewards(0, this.bob.address);
        reward = (parseFloat(reward.toString()).toPrecision(19))/1e18;
        expect(reward).to.equal(0.024051890432098762);
    })


    it("Should check pool balance after staking", async function () {
        await this.staking.connect(this.bob).stake(0, getBigNumber(1));
        let pool0Balance = await this.staking.totalStaked(0);
        expect(pool0Balance).to.equal(getBigNumber(1));

        await this.staking.connect(this.carol).stake(0, getBigNumber(1));
        await this.staking.connect(this.alice).stake(0, getBigNumber(10));

        pool0Balance = await this.staking.totalStaked(0);
        expect(pool0Balance).to.equal(getBigNumber(12));
    })

    it("Should check pools balance after staking in different pools", async function () {
        await this.staking.connect(this.bob).stake(0, getBigNumber(1));
        let pool0Balance = await this.staking.totalStaked(0);
        expect(pool0Balance).to.equal(getBigNumber(1));

        await this.staking.connect(this.carol).stake(1, getBigNumber(1));
        await this.staking.connect(this.alice).stake(1, getBigNumber(10));

        pool0Balance = await this.staking.totalStaked(0);
        expect(pool0Balance).to.equal(getBigNumber(1));

        let pool1Balance = await this.staking.totalStaked(1);
        expect(pool1Balance).to.equal(getBigNumber(11));
    })
})
