// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Utils {

    function isContract(address addr) public returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}
