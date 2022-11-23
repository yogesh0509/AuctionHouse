const { developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

const tokenUri = "ipfs://bafyreiflh4wjd2shgk2kguff5gl5uv6ifpdszfgfep2itve3tdzqugx7mu/metadata.json";

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    let chainId = network.config.chainId;
    let IdentityNftAddress, AuctionHouseAddress;

    if (developmentChains.includes(network.name)) {
        const IdentityNft = await ethers.getContract("IdentityNft");
        const AuctionHouse = await ethers.getContract("AuctionHouse");
        await IdentityNft.mintNft(tokenUri);
        await IdentityNft.mintNft(tokenUri);
        IdentityNftAddress = IdentityNft.address;
        AuctionHouseAddress = AuctionHouse.address
       
    }
    else {
        IdentityNftAddress = networkConfig[chainId]["IdentityNftAddress"];
        AuctionHouseAddress = networkConfig[chainId]["AuctionHouseAddress"];
    }

    const arguments = [IdentityNftAddress, AuctionHouseAddress]
    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : 6
    const Marketplace = await deploy("Marketplace", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: waitBlockConfirmations
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(Marketplace.address, arguments)
    }
}

module.exports.tags = ["all", "marketplace", "main"]
