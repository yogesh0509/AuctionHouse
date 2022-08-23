const { developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const arguments = [
        3600
    ]
    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : 6
    const AuctionHouse = await deploy("AuctionHouse", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: waitBlockConfirmations
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(AuctionHouse.address, arguments)
    }
}

module.exports.tags = ["all", "auctionhouse"]
