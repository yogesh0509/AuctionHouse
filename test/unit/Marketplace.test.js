const { assert, expect } = require("chai");
const { network, deployments, ethers } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("identity nft unit tests", () => {
        let MarketplaceContract, Marketplace

        beforeEach(async () => {
            accounts = await ethers.getSigners()
            await deployments.fixture(["all"])
            MarketplaceContract = await ethers.getContract("Marketplace")
            Marketplace = MarketplaceContract.connect(accounts[0])
        })

        describe("register as a buyer", () => {

            it("check for buyer that already exists", async () => {
                await Marketplace.register(accounts[1].address);
                await expect(Marketplace.register(accounts[1].address)).to.be.revertedWith("BuyerAlreadyRegistered")
            })

            // it("check for nft minted event", async () => {
            //     await expect(Marketplace.mintNft(accounts[1].address)).to.emit(Marketplace, "nftminted")
            // })

        })
    })