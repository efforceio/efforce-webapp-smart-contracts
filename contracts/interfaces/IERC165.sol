// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC165 {

    /*
        @notice Returns true if the interfaceID is implemented by the smart contract.
        @param interfaceID The target interface id.
        @return True if the target interface id is implemented by the smart contract, false otherwise.
    */
    function supportsInterface(bytes4 interfaceID) external view returns(bool);

}
