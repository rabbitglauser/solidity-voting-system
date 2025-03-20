// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DAOQuadraticVoting is Ownable {
    struct Candidate {
        string name;
        uint voteCount;
    }

    struct Proposal {
        string description;
        uint voteCount;
        bool executed;
        address newContractAddress;
        mapping(address => bool) hasVoted;
    }

    IERC20 public governanceToken;
    ERC721 public voterNFT; // NFT-Based Voter ID
    IMultiSigWallet public treasuryWallet; // Multi-Sig Wallet

    uint public votingStart;
    uint public votingEnd;

    mapping(address => mapping(uint => uint)) public quadraticVotes;
    Candidate[] public candidates;
    Proposal[] public proposals;

    event Voted(address indexed voter, uint candidateIndex, uint votesUsed);
    event ProposalCreated(uint proposalId, string description, address newContract);
    event ProposalExecuted(uint proposalId, address newContract);

    modifier onlyNFTVoter() {
        require(voterNFT.balanceOf(msg.sender) > 0, "You need an NFT voter ID");
        _;
    }

    modifier votingOpen() {
        require(block.timestamp >= votingStart && block.timestamp <= votingEnd, "Voting is closed");
        _;
    }

    constructor(
        string[] memory _candidateNames,
        address _tokenAddress,
        address _nftAddress,
        address _multiSigWallet
    ) {
        governanceToken = IERC20(_tokenAddress);
        voterNFT = ERC721(_nftAddress);
        treasuryWallet = IMultiSigWallet(_multiSigWallet);

        for (uint i = 0; i < _candidateNames.length; i++) {
            candidates.push(Candidate({name: _candidateNames[i], voteCount: 0}));
        }
    }

    /**
     * @dev Quadratic Voting - More votes cost exponentially more tokens.
     */
    function vote(uint candidateIndex, uint votes) external votingOpen onlyNFTVoter {
        require(candidateIndex < candidates.length, "Invalid candidate index");

        uint cost = votes * votes;
        require(governanceToken.transferFrom(msg.sender, address(this), cost), "Token transfer failed");

        quadraticVotes[msg.sender][candidateIndex] += votes;
        candidates[candidateIndex].voteCount += votes;

        emit Voted(msg.sender, candidateIndex, votes);
    }

    /**
     * @dev Create a Proposal (For Upgrading Contract).
     */
    function createProposal(string memory _description, address _newContractAddress) external onlyOwner {
        Proposal storage proposal = proposals.push();
        proposal.description = _description;
        proposal.voteCount = 0;
        proposal.executed = false;
        proposal.newContractAddress = _newContractAddress;

        emit ProposalCreated(proposals.length - 1, _description, _newContractAddress);
    }

    /**
     * @dev Vote on a Proposal (DAO Governance).
     */
    function voteOnProposal(uint proposalId) external onlyNFTVoter {
        require(proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.hasVoted[msg.sender], "Already voted");

        uint userBalance = governanceToken.balanceOf(msg.sender);
        require(userBalance > 0, "No governance tokens");

        proposal.voteCount += userBalance;
        proposal.hasVoted[msg.sender] = true;
    }

    /**
     * @dev Execute an Approved Proposal.
     */
    function executeProposal(uint proposalId) external onlyOwner {
        require(proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCount > 1000, "Not enough votes to execute"); // DAO threshold

        proposal.executed = true;

        // TODO Upgrade contract logic (dummy execution, actual migration would need proxy contracts)
        emit ProposalExecuted(proposalId, proposal.newContractAddress);
    }

    /**
     * @dev Multi-Sig Treasury: Request Fund Release.
     */
    function requestTreasuryRelease(address payable _to, uint256 _amount) external onlyOwner {
        bytes memory data;
        treasuryWallet.executeTransaction(_to, _amount, data);
    }

    /**
     * @dev Get all Candidates.
     */
    function getCandidates() external view returns (Candidate[] memory) {
        return candidates;
    }
}