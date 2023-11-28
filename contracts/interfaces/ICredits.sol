// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface ICredits {

    struct Vintage {
        uint256 totalCredits;
        uint256 availableCredits;
        uint256 price;
        uint256 state;
        uint256 projectId;
    }

    function getVintage(uint256 vintageId) external view returns(Vintage memory);
    function safeMint(address to, uint256 id, uint256 amount, bytes calldata data) external;
    function updateVintageAvailability(uint256 vintageId, uint256 availability) external;
    function burn(address _from, uint256 _id, uint256 _amount, bytes calldata) external;

}
