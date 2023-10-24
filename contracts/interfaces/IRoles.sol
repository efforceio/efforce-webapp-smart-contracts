// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IRoles {

    /*
        The roles defined in this interfaces are:

        - Contract owner: can withdraw funds from the smart contract, assign/revoke admin roles to/from accounts,
            and has all the permissions assigned to admins and managers;
        - Managers: can create projects and open funding rounds;
        - Admins: can allow addresses to own and transfer project credits.
    */

    /*
        @notice Assigns the admin role to the input account.
        @dev Can be invoked only by the contract owner.
        @param account The target account.
        @param admin If true, the target account will be assigned the admin role, otherwise it will be revoked.
    */
    function setAdmin(address account, bool admin) external;

    /*
        @notice Sets the input account as the new contract owner, replacing the previous one.
        @dev Can be invoked only by the contract owner.
        @param account The address of the new contract owner.
    */
    function setOwner(address account) external;

    /*
        @notice Returns true if the input account is an admin, false otherwise
        @param account The target account.
        @return True if the target account is an admin, false otherwise.
    */
    function isAdmin(address account) external view returns(bool);

    function getOwner() external view returns(address);

    /*
        @notice Emitted when the role is assigned to or revoked from the target account or when the target
            is the new contract owner (in this case isAdmin is always false).
        @dev When the contract owner is assigned to a new address, isAdmin is set to false.
        @param account The target account.
        @param isOwner True if the target account is the new contract owner.
        @param isAdmin True if the target account is admin.
    */
    event RoleAssignment(address indexed account, bool isOwner, bool isAdmin);

}
