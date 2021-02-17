const { ethers } = require("hardhat")
const { expect } = require("chai")
const { time , getBigNumber} = require("./utilities")
var abi = require('ethereumjs-abi')

describe("OptionNFT", function () {

    before(async function () {
        this.OptionNFTStake = await ethers.getContractFactory("OptionNFTMock");
        this.roomToken = await ethers.getContractFactory("NFTRoomTokenMock");
        this.signers = await ethers.getSigners()
        this.alice = this.signers[0]
        this.bob = this.signers[1]
        this.carol = this.signers[2]
        this.dev = this.signers[4]
    })

    beforeEach(async function () {
        this.staking = await this.OptionNFTStake.deploy()
        await this.staking.deployed()

        this.room = await this.roomToken.deploy()
        await this.room.deployed()

        this.staking.setRoomTokenAddress(this.room.address);

        // Putting alice as the wallet...
        await this.room.transfer(this.dev.address, getBigNumber(1000000))
        await this.room.connect(this.dev).approve(this.staking.address,
            getBigNumber(1000000), { from: this.dev.address });

        //sending some room tokens to the accounts...
        await this.room.transfer(this.alice.address, "1000")
        await this.room.transfer(this.bob.address, getBigNumber(50000))
        await this.room.transfer(this.carol.address, getBigNumber(1000))

        await this.room.connect(this.bob).approve(this.staking.address,
            getBigNumber(50000), { from: this.bob.address });

        await this.room.connect(this.alice).approve(this.staking.address,
            getBigNumber(1000), { from: this.alice.address });

        await this.room.connect(this.carol).approve(this.staking.address,
            getBigNumber(1000), { from: this.carol.address });

    })

    it("Should return capitals for the pools", async function () {
        let capital = await this.staking.capital(0 );
        expect(capital).to.equal(50);
        capital = await this.staking.capital(1 );
        expect(capital).to.equal(40);
        capital = await this.staking.capital(2 );
        expect(capital).to.equal(30);
        capital = await this.staking.capital(3 );
        expect(capital).to.equal(20);
        capital = await this.staking.capital(4 );
        expect(capital).to.equal(8);
    })

    it("Should return capitals for the first pool", async function () {
        let capital = await this.staking.checkAvailableToMint(0 );
        expect(capital).to.equal(50);
    })

    it("Should mint a tier and increase the burn balance to 50 ROOM tokens", async function () {
        await this.staking.connect(this.bob).mintTier(0);
        let burnBalance = await this.room.balanceOf("0x000000000000000000000000000000000000dEaD");
        expect(burnBalance).to.equal(getBigNumber(500));
    })

    it("Should revert when you already minted in a tier", async function () {
        await this.staking.connect(this.bob).mintTier(0);
        await expect(this.staking.connect(this.bob).mintTier(0)).to.be.revertedWith("account can not mint while holding nft")
    })

    it("Should revert ", async function () {
        await expect(this.staking.connect(this.bob).mintTier(1)).to.be.revertedWith("You should have previous tier")
    })

    it("Should be able to mint if I transfer the ", async function () {
        let index = 0;
        for (var i = 0; i <= 50 ; i++) {
            index ++;
            console.log(index);
            let minted = await this.staking.connect(this.bob).mintTier(0);
            await this.staking.connect(this.bob).safeTransferFrom(this.bob.address,
                this.alice.address, 0, 1, []);
        }
    })
})
