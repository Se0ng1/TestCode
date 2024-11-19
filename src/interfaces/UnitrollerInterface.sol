// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface UnitrollerInterface {
    function admin() external returns (address);
    function pendingAdmin() external returns (address);
    function comptrollerImplementation() external returns (address);
    function pendingComptrollerImplementation() external returns (address);
    function pauseGuardian() external returns (address);
    //admin function
    function _setPendingImplementation(address newPendingImplementation) external returns (uint);
    function _acceptImplementation() external returns (uint);
    function _setPendingAdmin(address newPendingAdmin) external returns (uint);
    function _acceptAdmin() external returns (uint);

}