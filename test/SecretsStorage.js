const {
  time,
  loadFixture,
} = require('@nomicfoundation/hardhat-toolbox/network-helpers');
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs');
const { expect } = require('chai');

describe('Storage Secret', async function () {
  async function deploySecretFixture() {
    // const ONE_GWEI = 1_000_000_000;
    const ONE_GWEI = 1_000_000_00;
    const lockedAmount = ONE_GWEI;

    const [owner, otherAccount] = await ethers.getSigners();

    const SecretsStorage = await ethers.getContractFactory('SecretsStorage');
    const secretsStorage = await SecretsStorage.deploy('', { value: lockedAmount });

    return { SecretsStorage, secretsStorage, lockedAmount, owner, otherAccount };
  }

  const { secretsStorage, lockedAmount, owner, otherAccount } = await loadFixture(deploySecretFixture);

  describe('Deployment', function () {
    describe('fails', function () {
      it('shouldnt deploy by invalid amount value', async () => {
        const { SecretsStorage } = await loadFixture(deploySecretFixture);

        await expect(SecretsStorage.deploy('', { value: 99 }))
          .to.be.revertedWith('Your payment has not reached the cost');
      });
    });

    describe('success', function () {
      it('should deploy', async () => {
        const { SecretsStorage } = await loadFixture(deploySecretFixture);

        const contract = await SecretsStorage.deploy('', { value: 100 });
        expect(await contract.getSecret()).to.eq('changeme');
      });
    });
  });

  describe('New Secret', async function () {
    describe('fails', () => {
      it('shouldnt set a new secret by invalid amount value', async () => {
        await expect(secretsStorage.newSecret('new secret'))
          .to.be.revertedWith('Your payment has not reached the cost');
      });

      it('shouldnt set a new secret by empty secret string', async () => {
        await expect(secretsStorage.newSecret('', { value: lockedAmount }))
          .to.be.revertedWith('Put a secret string');
      });
    });

    describe('success', () => {
      it('should set a new secret', async () => {
        expect(await secretsStorage.newSecret('new secret', { value: lockedAmount }))
          .not.to.be.reverted;
      });
    });
  });

  describe('Get Secret', function () {
    describe('fails', () => {
      it('shouldnt view the secret by other account', async () => {
        await expect(secretsStorage.connect(otherAccount).getSecret())
          .to.be.revertedWith('Only owner can view the secret');
      });
    });

    describe('success', () => {
      it('should view the secret', async () => {
        expect(await secretsStorage.connect(owner).getSecret())
          .not.to.be.reverted;
      });
    });
  });

  describe('Total Spent', function () {
    describe('fails', () => {
      it('shouldnt view total spent by other account', async () => {
        await expect(secretsStorage.connect(otherAccount).totalSpent())
          .to.be.revertedWith('You are not the owner');
      });
    });

    describe('success', () => {
      it('should view total spent', async () => {
        expect(await secretsStorage.connect(owner).totalSpent())
          .not.to.be.reverted;
      });
    });
  });

  describe('Change Owner', function () {
    describe('fails', () => {
      it('shouldnt change the owner by other account', async () => {
        await expect(secretsStorage.connect(otherAccount).changeOwner(otherAccount))
          .to.be.revertedWith('Only owner can set a new owner');
      });

      it('shouldnt change the owner by owner account', async () => {
        await expect(secretsStorage.connect(owner).changeOwner(owner))
          .to.be.revertedWith('You already is the owner');
      });
    });

    describe('success', async () => {
      it('should change the owner to another account', async () => {
        const { SecretsStorage, owner, otherAccount } = await loadFixture(deploySecretFixture);
        const _secretsStorage = await SecretsStorage.deploy('', { value: lockedAmount });

        expect(await _secretsStorage.connect(owner).changeOwner(otherAccount))
          .not.to.be.reverted;
        await expect(_secretsStorage.connect(otherAccount).changeOwner(owner))
          .to.emit(_secretsStorage, 'ChangedOwner')
          .withArgs(otherAccount.address, owner.address);
      });
    });
  });
});
