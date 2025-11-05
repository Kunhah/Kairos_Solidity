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

    function registerReferral(address _referrer) internal {
        require(approvedSeller[_referrer], NotAnApprovedSeller(_referrer));
        require(!approvedSeller[msg.sender, SellerCanNotSetReferrer(msg.sender)]);

        address current = referrals[user].referrer;
        address[] memory path;
        while (current != address(0) || path.length <= 5) {
            for (uint256 i = 0; i < path.length; i++) {    
                require(path[i] != current, CircularReferral(path));
            }
            path.push(current);
            current = referrals[current].referrer;
        }

        referrals[msg.sender] = _referrer;
        emit ReferralRegistered(msg.sender, _referrer);
    }

    /// @notice Distribute referral rewards up to 5 levels
    function distributeReferralRewards(address user, address token, uint256 amount) internal returns (uint256 distributedAmount) {
        
        require(amount != 0, ZeroAmount());
        uint256 remaining = amount;
        address current = referrals[user].referrer;
        uint256[] memory levelPercentages = getPercentages();

        for (uint8 i = 0; i < 5 && current != address(0); i++) {
            uint256 reward = (amount * levelPercentages[i]) / TOTAL_PERCENTAGE;
            distributedAmount += reward;
            if (reward > 0) {
                IERC20(token).trySafeTransferFrom(user, current, reward);
                emit ReferralPaid(current, reward, i + 1);
                remaining -= reward;
            }
            current = referrals[current].referrer;
        }
    }

    function getReferrer(address user) external view returns (address) {
        return referrals[user].referrer;
    }

    function modifySeller(address _seller, bool _approved) external onlyOwner {
        approvedSeller[_seller] = _approved;
    }
    
    function getPercentages() external pure returns (uint256[5]) {
        return [350_000, 150_000, 75_000, 35_000, 15_000]; // total of 62.5%
    }
}