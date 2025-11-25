// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ReferralSystem is Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public approvedSeller;
    mapping(address => address) public referrals;

    event ReferralRegistered(address indexed user, address indexed referrer);
    event ReferralPaid(address indexed referrer, uint256 amount, uint8 level);

    error NotAnApprovedSeller(address seller);
    error CircularReferral(address[] path);
    error SellerCanNotSetReferrer(address seller);
    error ZeroAmount();

    uint256 constant TOTAL_PERCENTAGE = 1_000_000; // 100%

    constructor() Ownable(msg.sender) {}

    function registerReferral(address _referrer) external {
        require(approvedSeller[_referrer], NotAnApprovedSeller(_referrer));
        require(!approvedSeller[msg.sender], SellerCanNotSetReferrer(msg.sender));

        referrals[msg.sender] = _referrer;
        address current = msg.sender;
        //address current = referrals[_referrer].referrer;
        
        address[] memory path;
        uint256 pathLength = 0;

        while (current != address(0) && pathLength < 6) {
            for (uint256 i = 0; i < pathLength; i++) {    
                require(path[i] != current, CircularReferral(path));
            }
            path[pathLength] = current;
            pathLength++;
            current = referrals[current];
        }

        emit ReferralRegistered(msg.sender, _referrer);
    }

    /// @notice Distribute referral rewards up to 5 levels
    function distributeReferralRewards(address user, address token, uint256 amount) internal returns (uint256 distributedAmount) {
        
        require(amount != 0, ZeroAmount());
        uint256 remaining = amount;
        address current = referrals[user];
        uint24[5] memory levelPercentages = getPercentages();

        for (uint8 i = 0; i < 5 && current != address(0); i++) {
            uint256 reward = (amount * levelPercentages[i]) / TOTAL_PERCENTAGE;
            distributedAmount += reward;
            if (reward > 0) {
                IERC20(token).safeTransfer(current, reward);
                emit ReferralPaid(current, reward, i + 1);
                remaining -= reward;
            }
            current = referrals[current];
        }
    }

    function getReferrer(address user) external view returns (address) {
        return referrals[user];
    }

    function modifySeller(address _seller, bool _approved) external onlyOwner {
        approvedSeller[_seller] = _approved;
    }
    
    function getPercentages() public pure returns (uint24[5] memory) {
        return [350_000, 150_000, 75_000, 35_000, 15_000]; // total of 62.5%
    }
}