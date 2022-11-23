const { assert, expect } = require("chai");
const { network, deployments, ethers } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");

const tokenUri = "ipfs://bafyreiflh4wjd2shgk2kguff5gl5uv6ifpdszfgfep2itve3tdzqugx7mu/metadata.json";

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("marketplace unit tests", () => {
        let MarketplaceContract, Marketplace

        beforeEach(async () => {
            accounts = await ethers.getSigners()
            await deployments.fixture(["main"])
            MarketplaceContract = await ethers.getContract("Marketplace")
            Marketplace = MarketplaceContract.connect(accounts[0])

        })

        describe("checking constructor", () => {
            it("initial auction state", async () => {
                assert.equal((await Marketplace.s_auctionState()).toString(), "false")
            })

            it("check current player count", async () => {
                // We have minted a nft before deployment of Marketplace contract. 
                // check deploy scripts....
                assert.equal((await Marketplace.s_playerCount()).toString(), "1")
            })
        })

        describe("check when start auction is triggered", () => {

            it("reverts if buyer has not registered", async () => {
                await expect(Marketplace.bid()).to.be.revertedWith("BuyerNotRegistered")
            })

            it("reverts if auction has not started", async () => {
                await Marketplace.register()
                await expect(Marketplace.bid()).to.be.revertedWith("AuctionHasEnded")
            })

            it("reverts if start auction is called and caller is not the owner", async () => {
                Marketplace = MarketplaceContract.connect(accounts[1])
                await expect(Marketplace.startAuction()).to.be.revertedWith("Ownable: caller is not the owner")
            })

            it("auction will be started if enough time has passed", async () => {
                await network.provider.send("evm_increaseTime", [2*86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                // This will trigger the start auction function.
                await expect(Marketplace.performUpkeep([])).to.emit(Marketplace, "AuctionStarted");
                assert.equal((await Marketplace.s_auctionState()).toString(), "true")
            })
        })

        describe("checkupkeep", () => {

            it("initial start auction upkeepNeeded", async () => {

                await network.provider.send("evm_increaseTime", [2*86400])
                await network.provider.request({ method: "evm_mine", params: [] })

                const {upkeepNeeded}  = await Marketplace.callStatic.checkUpkeep("0x")
                assert.equal(upkeepNeeded, true)
            })

            it("end auction upkeepNeeded", async () => {

                await network.provider.send("evm_increaseTime", [2*86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await Marketplace.performUpkeep([])

                await network.provider.send("evm_increaseTime", [86400])
                await network.provider.request({ method: "evm_mine", params: [] })

                const {upkeepNeeded}  = await Marketplace.callStatic.checkUpkeep("0x")
                assert.equal(upkeepNeeded, true)
            })

        })


        describe("chainlink keepers", () => {

            it("end the auction using chainlink keepers", async () => {

                await Marketplace.register()

                await network.provider.send("evm_increaseTime", [2*86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await Marketplace.performUpkeep([])

                await Marketplace.bid({ value: 100 })

                await network.provider.send("evm_increaseTime", [86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await expect(Marketplace.performUpkeep([])).to.emit(Marketplace, "AuctionEnded");
            })

        })

        describe("auction ended", () => {

            it("check if the funds have been transferred", async () => {

                await Marketplace.register()

                await network.provider.send("evm_increaseTime", [2*86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await Marketplace.performUpkeep([])

                await Marketplace.bid({ value: 100 })
                assert.equal((await Marketplace.provider.getBalance(Marketplace.address)).toString(), "0")

                await network.provider.send("evm_increaseTime", [86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await Marketplace.performUpkeep([])
                assert.equal((await Marketplace.provider.getBalance(Marketplace.address)).toString(), "100")

            })

        })

        describe("get result from chainlink api", () => {

            it("emit event request fulfilled", async () => {

                await Marketplace.register()

                await network.provider.send("evm_increaseTime", [2*86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await Marketplace.performUpkeep([])

                await network.provider.send("evm_increaseTime", [86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await Marketplace.performUpkeep([])

                await network.provider.send("evm_increaseTime", [86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await expect(Marketplace.performUpkeep([])).to.emit(Marketplace, "RequestFulfilled");
            })

            it("test for production", async () => {

                await Marketplace.register()

                await network.provider.send("evm_increaseTime", [2*86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await Marketplace.performUpkeep([])

                const tx = await Marketplace.bid({ value: 100 })
                const txreceipt = await tx.wait(1)
                console.log(txreceipt.from)
                console.log(accounts[0].address)
            })
        })

        describe("returning variables", () => {

            it("get all buyers", async () => {

                await Marketplace.register()
                console.log(await Marketplace.getBuyers())                
            })
            it("no of players purchasd by a registrant", async () => {

                await Marketplace.register()
                await network.provider.send("evm_increaseTime", [2*86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await Marketplace.performUpkeep([])

                await Marketplace.bid({ value: 100 })

                await network.provider.send("evm_increaseTime", [86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await Marketplace.performUpkeep([])
                
                assert.equal((await Marketplace.getPlayersPurchased(accounts[0].address)).toString(), 1) 
            })
            it("sum spent by a registrant", async () => {

                await Marketplace.register()
                await network.provider.send("evm_increaseTime", [2*86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await Marketplace.performUpkeep([])

                await Marketplace.bid({ value: 100 })

                await network.provider.send("evm_increaseTime", [86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await Marketplace.performUpkeep([])

                await network.provider.send("evm_increaseTime", [86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await Marketplace.performUpkeep([])

                await Marketplace.bid({ value: 200 })                

                await network.provider.send("evm_increaseTime", [86400])
                await network.provider.request({ method: "evm_mine", params: [] })
                await Marketplace.performUpkeep([])

                assert.equal((await Marketplace.moneyspent(accounts[0].address)).toString(), 300)
            })
        })
    })