// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRoles {

    /*
        The roles defined in this interfaces are:

        - Contract owner: can withdraw funds from the smart contract, assign/revoke admin roles to/from accounts, and has all the permissions assigned to admins and managers;
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
        @notice Assigns the manager role to the input account.
        @dev Can be invoked only by the contract owner.
        @param account The target account.
        @param admin If true, the target account will be assigned the manager role, otherwise it will be revoked.
    */
    function setManager(address account, bool manager) external;

    /*
        @notice Sets the input account as the new contract owner, replacing the previous one.
        @dev Can be invoked only by the contract owner.
        @param account The address of the new contract owner.
    */
    function setOwner(address account) external;

    /*
        @notice Returns true if the input account is an admin, false otherwise
        @param account The target account.
    */
    function isAdmin(address account) external returns(bool);

    /*
        @notice Returns true if the input account is a manager, false otherwise
        @param account The target account.
    */
    function isManager(address account) external returns(bool);

    /*
        @notice Emitted when the role is assigned to or revoked from the target account or when the target is the new contract owner (in this case isRevoked is always false).
        @dev When the contract owner is assigned to a new address, isRevoked is set to false.
        @dev The role is set to 0 if admin, 1 if manager, 2 if contract owner.
        @param account The target account.
        @param role The role that is assigned or revoked.
        @param isRevoked If the role is revoked, this field is set to true and false otherwise.
    */
    event RoleAssignment(address indexed account, uint8 role, bool isRevoked);

}
