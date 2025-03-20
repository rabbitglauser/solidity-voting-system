// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Import OpenZeppelin's ERC-20 Token Standard
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VotingSystem {
    struct Candidate {
        string name;
        uint voteCount;
    }

    IERC20 public rewardToken;
    uint public rewardAmount = 10 * (10 ** 18); // 10 tokens per vote

    uint public votingStart;
    uint public votingEnd;
    address public owner;

    mapping(address => bool) public hasVoted;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bytes32) private voteHashes; // Store hashed votes
    mapping(address => uint) private voterChoices; // Track previous votes

    Candidate[] public candidates;
    bool public votingEnded = false; // Track voting status

    event Voted(address indexed voter, string candidate);
    event CandidateAdded(string candidate);
    event VoteChanged(address indexed voter, string newCandidate);

    // Modifier to check if voting is open
    modifier votingOpen() {
        require(block.timestamp >= votingStart && block.timestamp <= votingEnd, "Voting is not open");
        _;
    }

    // Modifier to restrict function access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Modifier to restrict voting to whitelisted users
    modifier onlyWhitelisted() {
        require(isWhitelisted[msg.sender], "You are not whitelisted to vote");
        _;
    }

    constructor(string[] memory _candidateNames, address _tokenAddress, uint _votingDuration) {
        owner = msg.sender;
        rewardToken = IERC20(_tokenAddress);
        votingStart = block.timestamp;
        votingEnd = block.timestamp + _votingDuration;

        for (uint i = 0; i < _candidateNames.length; i++) {
            candidates.push(Candidate({name: _candidateNames[i], voteCount: 0}));
        }
    }

    // Function to add a voter to the whitelist
    function addVoter(address _voter) external onlyOwner {
        isWhitelisted[_voter] = true;
    }

    // Function to add a new candidate
    function addCandidate(string memory _name) external onlyOwner {
        candidates.push(Candidate({name: _name, voteCount: 0}));
        emit CandidateAdded(_name);
    }

    // Function to submit a hashed vote for privacy
    function submitVote(bytes32 _voteHash) external votingOpen {
        require(voteHashes[msg.sender] == 0, "You have already voted");
        voteHashes[msg.sender] = _voteHash;
    }

    // Function to reveal a vote after voting ends
    function revealVote(uint candidateIndex, string memory secret) external {
        require(votingEnded, "Voting is still open");
        require(voteHashes[msg.sender] != 0, "No vote found");

        bytes32 computedHash = keccak256(abi.encodePacked(candidateIndex, secret));
        require(voteHashes[msg.sender] == computedHash, "Invalid vote reveal");

        candidates[candidateIndex].voteCount += 1;
    }

    // Function to cast a vote (whitelisted users only)
    function vote(uint candidateIndex) external votingOpen onlyWhitelisted {
        require(!hasVoted[msg.sender], "You have already voted");
        require(candidateIndex < candidates.length, "Invalid candidate index");

        hasVoted[msg.sender] = true;
        candidates[candidateIndex].voteCount += 1;
        voterChoices[msg.sender] = candidateIndex;

        // Transfer reward tokens for participation
        require(rewardToken.transfer(msg.sender, rewardAmount), "Token transfer failed");

        emit Voted(msg.sender, candidates[candidateIndex].name);
    }

    // Function to allow voters to change their vote
    function changeVote(uint newCandidateIndex) external votingOpen {
        require(hasVoted[msg.sender], "You haven't voted yet");
        require(newCandidateIndex < candidates.length, "Invalid candidate index");

        uint previousCandidateIndex = voterChoices[msg.sender];
        candidates[previousCandidateIndex].voteCount -= 1;
        candidates[newCandidateIndex].voteCount += 1;

        voterChoices[msg.sender] = newCandidateIndex;

        emit VoteChanged(msg.sender, candidates[newCandidateIndex].name);
    }

    // Function to retrieve candidate votes
    function getCandidateVotes(uint candidateIndex) external view returns (uint) {
        require(candidateIndex < candidates.length, "Invalid candidate index");
        return candidates[candidateIndex].voteCount;
    }

    // Function to get the winner of the election
    function getWinner() external view returns (string memory) {
        uint maxVotes = 0;
        uint winnerIndex = 0;

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                winnerIndex = i;
            }
        }

        return candidates[winnerIndex].name;
    }
}
