// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface ICredits {

    struct Vintage {
        uint totalCredits;
        uint availableCredits;
        uint price;
        uint state;
        uint projectId;
    }

    function getVintage(uint vintageId) external view returns(Vintage memory);
    function safeMint(address to, uint id, uint amount, bytes calldata data) external;
    function updateVintageAvailability(uint vintageId, uint availability) external;
    function burn(address _from, uint _id, uint _amount, bytes calldata) external;

}
