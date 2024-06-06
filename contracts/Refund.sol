// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./modules/RolesModifier.sol";
import "./interfaces/ICredits.sol";
import "./interfaces/IBank.sol";
import "./interfaces/IERC1155.sol";

contract Refund is RolesModifier {

    mapping(uint=>uint) private projectIdToRefund;
    address immutable public creditsAddress;
    address immutable public bankAddress;

    constructor(address rolesAddress, address _creditsAddress, address _bankAddress) {
        rolesModifierInitializer(rolesAddress);
        creditsAddress = _creditsAddress;
        bankAddress = _bankAddress;
    }

    function setRefund(uint projectId, uint refund)
        external
        adminOrOwner(msg.sender)
    {
        projectIdToRefund[projectId] = refund;
    }

    function receiveRewards(uint[] calldata creditIds)
        external
    {
        uint reward;
        uint len = creditIds.length;
        uint i = 0;
        while (i < len) {
            uint projectId = ICredits(creditsAddress).getVintage(creditIds[i]).projectId;
            uint balance = IERC1155(creditsAddress).balanceOf(msg.sender, creditIds[i]);
            reward += balance * projectIdToRefund[projectId];
            ICredits(creditsAddress).burn(msg.sender, creditIds[i], balance, "");
            unchecked {
                i++;
            }
        }

        IBank(bankAddress).withdraw(msg.sender, reward);
        emit RewardReceived(msg.sender, creditIds);
    }

    function getProjectReward(uint projectId)
        external
        view
        returns(uint)
    {
        return projectIdToRefund[projectId];
    }

    event RewardReceived(address indexed receiver, uint[] creditIds);

}
