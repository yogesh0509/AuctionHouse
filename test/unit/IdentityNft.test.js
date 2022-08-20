const { assert, expect } = require("chai");
const { network, deployments, ethers } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");

const tokenUri = "ipfs://bafyreiflh4wjd2shgk2kguff5gl5uv6ifpdszfgfep2itve3tdzqugx7mu/metadata.json";

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("identity nft unit tests", () => {
        let IdentityNftContract, IdentityNft
        const TOKEN_ID = 0

        beforeEach(async () => {
            accounts = await ethers.getSigners()
            await deployments.fixture(["all"])
            IdentityNftContract = await ethers.getContract("IdentityNft")
            IdentityNft = IdentityNftContract.connect(accounts[0])
        })

        describe("mint nft", () => {

            it("check for token counter", async () => {
                await IdentityNft.mintNft(accounts[1].address);
                assert.equal((await IdentityNft.getTokenCounter()).toString(), 1)
            })

            it("check for nft minted event", async () => {
                await expect(IdentityNft.mintNft(accounts[1].address)).to.emit(IdentityNft, "nftminted")
            })

        })

        describe("token uri", ()=>{
            it("check token uri", async()=>{
                await IdentityNft.mintNft(accounts[1].address);
                assert.equal((await IdentityNft.tokenURI(0)).toString(), tokenUri)
            })
        })
    })