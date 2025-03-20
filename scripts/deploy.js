const hre = require("hardhat");

async function main() {
    const VotingSystem = await hre.ethers.getContractFactory("VotingSystem");
    const voting = await VotingSystem.deploy(["Alice", "Bob", "Charlie"]);

    await voting.waitForDeployment();

    console.log(`Voting contract deployed at: ${voting.target}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
