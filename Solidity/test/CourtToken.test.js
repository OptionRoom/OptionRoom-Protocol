const { ethers } = require("hardhat")
const { expect } = require("chai")
const { getBigNumber} = require("./utilities")

describe("CourtToken", function () {
    before(async function () {
        this.CourtToken = await ethers.getContractFactory("CourtTokenMock")
        this.signers = await ethers.getSigners()
        this.alice = this.signers[0]
        this.bob = this.signers[1]
        this.carol = this.signers[2]
    })

    beforeEach(async function () {
        this.court = await this.CourtToken.deploy()
        await this.court.deployed()
        await this.court.setGovernanace(this.bob.address);
    })

    it("should have correct name and symbol and decimal", async function () {
        const name = await this.court.name()
        const symbol = await this.court.symbol()
        const decimals = await this.court.decimals()
        expect(symbol).to.equal("COURT")
        expect(name).to.equal("OptionCourt Token")
        expect(decimals).to.equal(18)
    })

    it("should only allow owner to mint token", async function () {
        await this.court.connect(this.bob).addMinter(this.bob.address);

        await this.court.connect(this.bob).mint(this.alice.address, getBigNumber(5));
        await this.court.connect(this.bob).mint(this.bob.address, getBigNumber(5));
        await expect(this.court.connect(this.alice).mint(this.alice.address, getBigNumber(5))).to.be.revertedWith(
            "Caller is not a minter"
        )

        const totalSupply = await this.court.totalSupply()
        const aliceBal = await this.court.balanceOf(this.alice.address)
        const bobBal = await this.court.balanceOf(this.bob.address)
        const carolBal = await this.court.balanceOf(this.carol.address)

        expect(totalSupply).to.equal(getBigNumber(11))
        expect(bobBal).to.equal(getBigNumber(5))
        // Alice is the deployer of the contract...
        expect(aliceBal).to.equal(getBigNumber(6))
        expect(carolBal).to.equal(getBigNumber(0))
    })


    it("should supply token transfers properly", async function () {
        await this.court.connect(this.bob).addMinter(this.bob.address);

        await this.court.connect(this.bob).mint(this.alice.address, getBigNumber(100));
        await this.court.connect(this.bob).mint(this.bob.address, getBigNumber(1000));

        // Transferring some tokens.
        await this.court.connect(this.bob).transfer(this.carol.address, getBigNumber(10));
        const carolBal = await this.court.balanceOf(this.carol.address)
        expect(carolBal).to.equal(getBigNumber(10))

        const totalSupply = await this.court.totalSupply()
        expect(totalSupply).to.equal(getBigNumber(1101))

        const bobBal = await this.court.balanceOf(this.bob.address)
        expect(bobBal).to.equal(getBigNumber(990))
    })

    it("should fail if you try to do bad transfers", async function () {
        await this.court.connect(this.bob).addMinter(this.bob.address);

        await this.court.connect(this.bob).mint(this.alice.address, getBigNumber(100));
        await expect(this.court.connect(this.alice).
            transfer(this.carol.address, getBigNumber(110))).to.be.revertedWith("ERC20: transfer amount exceeds balance")
    })



    it("should fail when none minter tries to mint", async function () {
        await this.court.connect(this.bob).addMinter(this.bob.address);
        await this.court.connect(this.bob).addMinter(this.alice.address);

        await this.court.connect(this.bob).mint(this.carol.address, getBigNumber(5));
        await this.court.connect(this.alice).mint(this.carol.address, getBigNumber(5));

        await expect(this.court.connect(this.carol).mint(this.bob.address, getBigNumber(5))).to.be.revertedWith(
            "Caller is not a minter"
        )

        const totalSupply = await this.court.totalSupply()
        const carolBal = await this.court.balanceOf(this.carol.address)

        expect(totalSupply).to.equal(getBigNumber(11))
        expect(carolBal).to.equal(getBigNumber(10))
    })

})
