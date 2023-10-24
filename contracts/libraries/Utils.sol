// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

library Utils {

    function isContract(address addr)
        public
        view
        returns (bool)
    {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}
