// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract VotingSystem {
    struct Candidate {
        string name;
        uint voteCount;
    }

    uint public votingStart;
    uint public votingEnd;

    modifier votingOpen() {
        require(block.timestamp >= votingStart && votingEnd, "voting is not open");
    }

    address public owner;
    mapping(address => bool) public hasVoted;
    Candidate[] public candidates;

    event Voted(address indexed voter, string candidate);

    // functionality to map to restrict the voting
    mapping(address => bool) public isWhitelisted;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(string[] memory _candidateNames) {
        owner = msg.sender;
        for (uint i = 0; i < _candidateNames.length; i++) {
            candidates.push(Candidate({name: _candidateNames[i], voteCount: 0}));
        }
    }

    constructor(string[] memory _candidateNames) {
        owner = msg.sender;
        votingStart = block.timestamp;
        votingEnd = block.timestamp + _votingDuration;
        for (uint i = 0; i < _candidateNames.length; i++) {
            candidates.push(Candidate({name: _candidateNames[i], voteCount: 0}));
        }
    }

    function addVoter() external onlyOwner {
        isWhitelisted[_voter] = true;
    }

    function vote(uint candidateIndex) external {
        require(!hasVoted[msg.sender], "You have already voted");
        require(candidateIndex < candidates.length, "Invalid candidate index");

        hasVoted[msg.sender] = true;
        candidates[candidateIndex].voteCount += 1;

        emit Voted(msg.sender, candidates[candidateIndex].name);
    }

    function getCandidates() external view returns (Candidate[] memory) {
        return candidates;
    }

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

    // TODO owner can add candidates
    function addCandidate(string memory _name) external onlyOwner {
        candidates.push(Candidate({name: _name, voteCount: 0}));
    }


    // TODO voting period

    function vote(uint candidateIndex) external votingOpen {
        require(!hasVoted[msg.sender], "You have already voted");
        require(candidateIndex < candidates.length, "Invalid candidate index");

        hasVoted[msg.sender] = true;
        candidates[candidateIndex].voteCount += 1;

        emit Voted(msg.sender, candidates[candidateIndex].name);
    }

    // ToDO restrict people who can vote
    function vote(uint candidateIndex) external votingOpen onlyWhitelisted {
        require(!hasVoted[msg.sender], "You have already voted");
        require(candidateIndex < candidates.length, "Invalid candidate index");

        hasVoted[msg.sender] = true;
        candidates[candidateIndex].voteCount += 1;

        emit Voted(msg.sender, candidates[candidateIndex].name);
    }

    // TODO retrieve total votes

    // ToDO allow voters to change their votes

    // ToDo make votes private

    // ToDo implement a blockchain based reward token
}