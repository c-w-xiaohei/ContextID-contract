const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying ContextIDVault with account:", deployer.address);

    const ContextIDVault = await hre.ethers.getContractFactory("ContextIDVault");
    const vault = await ContextIDVault.deploy();
    await vault.waitForDeployment();

    const vaultAddress = await vault.getAddress();
    console.log("ContextIDVault deployed at:", vaultAddress);

    // Verify the contract on Etherscan/Blockscout
    if (hre.network.name === "injEVM") {
        console.log("Verifying contract on block explorer...");
        // 等待几秒钟，确保合约已经在网络上传播
        await new Promise(resolve => setTimeout(resolve, 30000));

        try {
            await hre.run("verify:verify", {
                address: vaultAddress,
                constructorArguments: [], // 我们的构造函数没有参数
            });
            console.log("Contract verified successfully.");
        } catch (e) {
            console.error("Verification failed:", e);
        }
    }

    console.log("Deployment completed successfully.");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});