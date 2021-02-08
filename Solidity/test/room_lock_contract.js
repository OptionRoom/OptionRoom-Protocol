const {
    BN,
} = require('@openzeppelin/test-helpers');

const helper = require('ganache-time-traveler');
const web3 = require('web3');

const RoomLockSimulator = artifacts.require("RoomLockSimulator");
const RoomToken = artifacts.require("RoomToken");

const SECONDS_IN_DAY = 86400;

const SEED_LOCK_RELEASE_DATE = 1614556800;
const PRIVATE_SALE_RELEASE_DATE = 1614556800;
const REWARD_PROTOCOL_LOCK_RELEASE_DATE = 1614556800;
const TEEM_LOCK_RELEASE_DATE = 1640995200;

contract('room_lock', (accounts) => {

    let orgTimeSnapShot;

    beforeEach(async () => {
        let snapshot = await helper.takeSnapshot();
        orgTimeSnapShot = snapshot['result'];
    });

    afterEach(async () => {
        await helper.revertToSnapshot(orgTimeSnapShot);
    });

    before(async () => {
        const roomLockSimulatorInstance = await RoomLockSimulator.deployed();
        const roomTokenInstance = await RoomToken.deployed();

        await roomLockSimulatorInstance.setLockedTokenExternal(roomTokenInstance.address);

        // Adding the four pools
        await roomLockSimulatorInstance.addSimulatedBeneficiary(accounts[0], 8800000, "Seed Lock", 1614556800, 300, 1 * SECONDS_IN_DAY);
        await roomLockSimulatorInstance.addSimulatedBeneficiary(accounts[1], 15000000, "Private Sale Lock", 1614556800, 150, 1 * SECONDS_IN_DAY);
        await roomLockSimulatorInstance.addSimulatedBeneficiary(accounts[2], 40000000, "Rewards Protocol Lock", 1614556800, 1, 1 * SECONDS_IN_DAY);
        await roomLockSimulatorInstance.addSimulatedBeneficiary(accounts[3], 10000000, "Team Lock", 1640995200, 4, 90 * SECONDS_IN_DAY);

        let deposit = new BN('8800000000000000000000000');// (new BN('8800000'));

        await roomTokenInstance.transfer(roomLockSimulatorInstance.address, deposit);
        await roomTokenInstance.balanceOf(roomLockSimulatorInstance.address);
    });

    it('Should return the current total number of tokens locked inside LockToken contract', async () => {
        const roomLockSimulatorInstance = await RoomLockSimulator.deployed();

        let totalLocked = await roomLockSimulatorInstance.getTotalLocked();
        assert.equal(web3.utils.fromWei(totalLocked), "73800000", "Total locked is in correct");
    });

    it('Should check the vested amount for account[0]', async () => {
        const roomLockSimulatorInstance = await RoomLockSimulator.deployed();
        const vestedAmount = await roomLockSimulatorInstance.getVestedAmount(0, accounts[0], SEED_LOCK_RELEASE_DATE);
        expect(Math.floor(web3.utils.fromWei(vestedAmount))).to.be.within(29333, 29334);
    });

    it('Should check the vested amount for account[1]', async () => {
        const roomLockSimulatorInstance = await RoomLockSimulator.deployed();
        const vestedAmount = await roomLockSimulatorInstance.getVestedAmount(1, accounts[1], PRIVATE_SALE_RELEASE_DATE);
        expect(Math.floor(web3.utils.fromWei(vestedAmount))).to.be.within(100000, 100001);
    });


    it('Should check the vested amount for account[2]', async () => {
        const roomLockSimulatorInstance = await RoomLockSimulator.deployed();
        const vestedAmount = await roomLockSimulatorInstance.getVestedAmount(2, accounts[2], REWARD_PROTOCOL_LOCK_RELEASE_DATE);
        expect(Math.floor(web3.utils.fromWei(vestedAmount))).to.be.within(40000000, 40000000);
    });


    it('Should check the vested amount for account[3]', async () => {
        const roomLockSimulatorInstance = await RoomLockSimulator.deployed();
        const vestedAmount = await roomLockSimulatorInstance.getVestedAmount(3, accounts[3], TEEM_LOCK_RELEASE_DATE);
        expect(Math.floor(web3.utils.fromWei(vestedAmount))).to.be.within(2500000, 2500000);
    });

    it('Should return a beneficiary information', async () => {
        const roomLockSimulatorInstance = await RoomLockSimulator.deployed();
        const beneficiaryInfo = await roomLockSimulatorInstance.getBeneficiaryInfo(0, accounts[0]);
    });

    it('Should return the time of the next batch of a holder for account[0]', async () => {
        const roomLockSimulatorInstance = await RoomLockSimulator.deployed();
        let startingDate = 1609520140;
        await helper.advanceBlockAndSetTime(startingDate);
        const nextBatchTime = await roomLockSimulatorInstance.getNextBatchTime(0, accounts[0], startingDate);
        assert.equal(nextBatchTime, SEED_LOCK_RELEASE_DATE, "Release date is not correct");
    });

    it('Should be able to claim if we advance the time', async () => {
        const roomLockSimulatorInstance = await RoomLockSimulator.deployed();

        await helper.advanceBlockAndSetTime(SEED_LOCK_RELEASE_DATE); //March 1, 2021 12:00:00 AM GMT
        const accountToCheckAgainst = accounts[0];

        const amountToClaim = await roomLockSimulatorInstance.getReleasableAmount(0, accountToCheckAgainst);
        const vestedAmountTimeBefore1 = await roomLockSimulatorInstance.getVestedAmount(0, accountToCheckAgainst, 1609532800);
        const vestedAmountTimeBefore2 = await roomLockSimulatorInstance.getVestedAmount(0, accountToCheckAgainst, 1614544000);
        const vestedAmountInTime = await roomLockSimulatorInstance.getVestedAmount(0, accountToCheckAgainst, SEED_LOCK_RELEASE_DATE);
        const vestedAmountTimeAfter1 = await roomLockSimulatorInstance.getVestedAmount(0, accountToCheckAgainst, 1614716800);
        const vestedAmountTimeAfter2 = await roomLockSimulatorInstance.getVestedAmount(0, accountToCheckAgainst, 1617308800);
        const vestedAmountTimeAfter3 = await roomLockSimulatorInstance.getVestedAmount(0, accountToCheckAgainst, 1619900800);

        console.log(await roomLockSimulatorInstance.getCurrentTime());
        console.log("Amount to claim at the start of the month: " + amountToClaim);
        console.log(web3.utils.fromWei(vestedAmountTimeBefore1));
        console.log(web3.utils.fromWei(vestedAmountTimeBefore2));
        console.log(web3.utils.fromWei(vestedAmountInTime));
        console.log(web3.utils.fromWei(vestedAmountTimeAfter1));
        console.log(web3.utils.fromWei(vestedAmountTimeAfter2));
        console.log(web3.utils.fromWei(vestedAmountTimeAfter3));
        expect(Math.floor(web3.utils.fromWei(vestedAmountInTime))).to.be.within(29333, 29334);
        expect(Math.floor(web3.utils.fromWei(vestedAmountTimeAfter1))).to.be.within(58666, 58667);

        const roomTokenInstance = await RoomToken.deployed();

        const lockBefore = (await roomTokenInstance.balanceOf(roomLockSimulatorInstance.address)).toString();
        const account0Before = (await roomTokenInstance.balanceOf(accountToCheckAgainst)).toString();

        console.log(web3.utils.fromWei(lockBefore) + " Locked balance before claim");
        console.log(web3.utils.fromWei(account0Before) + " account 0 balance before claim");

        await roomLockSimulatorInstance.claim(0);

        const lockAfter = (await roomTokenInstance.balanceOf(roomLockSimulatorInstance.address)).toString();
        const account0After = (await roomTokenInstance.balanceOf(accountToCheckAgainst)).toString();

        console.log(web3.utils.fromWei(account0After) + " account 0 after claim");
        console.log(web3.utils.fromWei(lockAfter) + " Locked balance after claim");

        let accountChangeAmount = new BN(account0After).sub(new BN(account0Before));

        expect(Math.floor(web3.utils.fromWei(accountChangeAmount))).to.be.within(29333, 29334);
    });

    it('Should check for the existence of 4 pools', async () => {
        const roomLockSimulatorInstance = await RoomLockSimulator.deployed();
        const poolsNumber = await roomLockSimulatorInstance.getPoolsCount();
        assert.equal(poolsNumber.valueOf(), 4, "There was error creating pools");
    });

    it('Should check for pools information', async () => {
        const roomLockSimulatorInstance = await RoomLockSimulator.deployed();
        var poolResult = await roomLockSimulatorInstance.getPoolInfo(0);

        assert.equal(poolResult.name.valueOf(), 'Seed Lock', "Error creating pools");
        assert.equal(poolResult.totalLocked.valueOf(), 8800000 * 1e18, "Number total locked of pool account[0] is wrong");
        assert.equal(poolResult.startReleasingTime.valueOf(), 1614556800, "Start releasing time is invalid for account[0]");
        assert.equal(poolResult.batchCount.valueOf(), 300, "Vesting count for pool account[0] is invalid");


        poolResult = await roomLockSimulatorInstance.getPoolInfo(1);

        assert.equal(poolResult.name.valueOf(), 'Private Sale Lock', "Error creating pools");
        assert.equal(poolResult.totalLocked.valueOf(), 15000000 * 1e18, "Number total locked of account[1] is wrong");
        assert.equal(poolResult.startReleasingTime.valueOf(), 1614556800, "Start releasing time is invalid for account[1]");
        assert.equal(poolResult.batchCount.valueOf(), 150, "Vesting count for pool account[1]1 is invalid");
    });
});
