// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "remix_tests.sol"; // Import the remix testing library
import "remix_accounts.sol"; // Import the remix accounts library
import "contracts/_ronx1.sol";// Import the contract to be tested


contract X3ProgramTest {
    X3Program x3Program;
    address owner = address(this);
    address upline1 = address(0x1);
    address referral1 = address(0x2);
    address referral2 = address(0x3);

    // Initialize the contract and set up initial state
    function beforeAll() public {
        x3Program = new X3Program();
    }

    // Test the payUpline function
    function testPayUpline() public {
        // Register upline1 with required parameters and ensure the function is payable
        x3Program.registerUpline{value: 25e18}(
            upline1,
            "John",
            "Doe",
            "profilePic.jpg",
            "john.doe@example.com"
        );
        
        // Register two referrals under upline1
        x3Program.registerUser{value: 25e18}(
            upline1,
            "Jane",
            "Doe",
            "profilePic2.jpg",
            "jane.doe@example.com",
            "password1",
            referral1
        );
        x3Program.registerUser{value: 25e18}(
            upline1,
            "Alice",
            "Smith",
            "profilePic3.jpg",
            "alice.smith@example.com",
            "password2",
            referral2
        );

        // Fund the contract for payouts
        (bool success, ) = payable(address(x3Program)).call{value: 100e18}("");
        require(success, "Funding contract failed");

        // Get initial earnings and cycle count
        (, , , uint256 initialCycleCount, uint256 initialEarnings, , , , , , ) = x3Program.getUserInfo(upline1);

        // Call payUpline to distribute earnings
        x3Program.payUpline(referral2);

        // Get updated user info
        (, , , uint256 newCycleCount, uint256 newEarnings, , , , , , ) = x3Program.getUserInfo(upline1);

        // Expected earnings should include the reward for level 1
        uint256 expectedEarnings = initialEarnings + x3Program.getLevelPrice(1);
        Assert.equal(newEarnings, expectedEarnings, "Earnings should increase by the level 1 price");

        Assert.equal(newCycleCount, initialCycleCount + 1, "Cycle count should be incremented");

        (, , uint256 newReferralCount, , , , , , , , ) = x3Program.getUserInfo(upline1);
        Assert.equal(newReferralCount, 0, "Referral count should be reset to 0");
    }
}