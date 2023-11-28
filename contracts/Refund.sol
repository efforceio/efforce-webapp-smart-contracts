// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./modules/RolesModifier.sol";
import "./interfaces/ICredits.sol";
import "./interfaces/IBank.sol";
import "./interfaces/IERC1155.sol";

contract Refund is RolesModifier {

    mapping(uint256=>uint256) private projectIdToRefund;
    address immutable public creditsAddress;
    address immutable public bankAddress;

    constructor(address rolesAddress, address _creditsAddress, address _bankAddress)
        RolesModifier(rolesAddress)
    {
        creditsAddress = _creditsAddress;
        bankAddress = _bankAddress;
    }

    function setRefund(uint256 projectId, uint256 refund)
        external
        adminOrOwner(msg.sender)
    {
        projectIdToRefund[projectId] = refund;
    }

    function receiveRewards(uint256[] calldata creditIds)
        external
    {
        uint256 reward;
        uint len = creditIds.length;
        uint256 i = 0;
        while (i < len) {
            uint256 projectId = ICredits(creditsAddress).getVintage(creditIds[i]).projectId;
            uint256 balance = IERC1155(creditsAddress).balanceOf(msg.sender, creditIds[i]);
            reward += balance * projectIdToRefund[projectId];
            ICredits(creditsAddress).burn(msg.sender, creditIds[i], balance, "");
            unchecked {
                i++;
            }
        }

        IBank(bankAddress).withdraw(msg.sender, reward);
        emit RewardReceived(msg.sender, creditIds);
    }

    function getProjectReward(uint256 projectId)
        external
        view
        returns(uint256)
    {
        return projectIdToRefund[projectId];
    }

    event RewardReceived(address indexed receiver, uint256[] creditIds);

}
