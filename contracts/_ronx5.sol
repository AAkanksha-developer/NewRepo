// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract X3Program {
    struct User {
        address upline;
        uint256 id;
        uint256 referralCount;
        uint256 cycleCount;
        uint256 earnings;
        uint8 partnerLevel;
        address[] referrals;
        string firstName;
        string lastName;
        string profilePic;
        string email;
        bytes32 passwordHash;
        address userAddress;
    }
     
    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;
    mapping(uint8 => uint256) public levelPrice;

    uint256 public lastUserId = 3;
    uint8 public constant LAST_LEVEL = 12;
    uint256 public constant BASIC_PRICE = 5e18;
    uint256 public constant REGISTRATION_FEE = 25e18;

    address public owner;

    event Registration(address indexed user, address indexed upline, uint256 userId, uint256 uplineId, uint256 fee);
    event NewReferral(address indexed user, address indexed referral);
    event NewCycle(address indexed user, uint256 cycleCount);
    event Earnings(address indexed user, uint256 amount);
    event LevelUpgraded(address indexed user, uint8 newLevel, uint256 price, uint256 uplineEarnings, uint256 ownerEarnings);

    constructor() {
        owner = msg.sender;

        users[owner] = User({
            upline: address(0),
            id: 1,
            referralCount: 0,
            cycleCount: 0,
            earnings: 0,
            partnerLevel: 1,
            referrals: new address[](0) ,
            firstName: "",
            lastName: "",
            profilePic: "",
            email: "",
            passwordHash: bytes32(0),
            userAddress: owner
        });

        idToAddress[1] = owner;

        // Initialize level prices
        levelPrice[1] = BASIC_PRICE;
        for (uint8 i = 2; i <= 8; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
        }
        levelPrice[9] = 1250e18;
        levelPrice[10] = 2500e18;
        levelPrice[11] = 5000e18;
        levelPrice[12] = 9900e18;
    }
    

    function registerUpline(
        address _upline,
        string memory firstName,
        string memory lastName,
        string memory profilePic,
        string memory email,
        string memory password 
    ) public payable {
        require(users[_upline].id == 0, "Upline already registered");
        //require(msg.value == REGISTRATION_FEE, "Incorrect registration cost");
        bytes32 passwordHash = keccak256(abi.encodePacked(password));
        // Register the upline
        users[_upline] = User({
            upline: address(0),
            id: lastUserId,
            referralCount: 0,
            cycleCount: 0,
            earnings: 0,
            partnerLevel: 1,
            referrals: new address[](0) ,
            firstName: firstName,
            lastName: lastName,
            profilePic: profilePic,
            email: email,
            passwordHash: passwordHash,
            userAddress: _upline
        });

        idToAddress[lastUserId] = _upline;
        lastUserId++;

        // Transfer registration fee to the contract owner
        payable(owner).transfer(msg.value);

        emit Registration(_upline, address(0), users[_upline].id, 0, REGISTRATION_FEE);
    }

    function registerUser(
        address _upline,
        string memory firstName,
        string memory lastName,
        string memory profilePic,
        string memory email,
        string memory password,
        address userAddress
    ) public payable {
        require(users[_upline].id != 0, "Upline does not exist");
        //require(msg.value == REGISTRATION_FEE, "Incorrect registration cost");
        // require(users[msg.sender].id == 0, "User already registered");

        bytes32 passwordHash = keccak256(abi.encodePacked(password));

        // Register new user
        users[msg.sender] = User({
            upline: _upline,
            id: lastUserId,
            referralCount: 0,
            cycleCount: 0,
            earnings: 0,
            partnerLevel: 1,
            referrals: new address[](0) ,
            firstName: firstName,
            lastName: lastName,
            profilePic: profilePic,
            email: email,
            passwordHash: passwordHash,
            userAddress: userAddress
        });

        idToAddress[lastUserId] = msg.sender;
        lastUserId++;

        // Manage referrals
        users[_upline].referralCount++;
        users[_upline].referrals.push(msg.sender);
        payable(owner).transfer(msg.value);
        
        // Handle the positioning and rewards
        handleReferral(msg.sender);

        // Transfer registration fee to the contract owner
        emit Registration(msg.sender, _upline, users[msg.sender].id, users[_upline].id, REGISTRATION_FEE);
    }

    function handleReferral(address _user) internal {
        address upline = users[_user].upline;

        if (users[upline].referralCount == 1 || users[upline].referralCount == 2) {
            // Reward the upline directly for the first and second referrals
            uint8 level = users[upline].partnerLevel;
            rewardUser(upline, levelPrice[level]);
        } else if (users[upline].referralCount == 3) {
            // On the third referral, the cycle completes, and the reward goes to the upline's upline
            address uplineOfUpline = users[upline].upline;
            uint8 level = users[uplineOfUpline].partnerLevel;
            if (uplineOfUpline != address(0)) {
                rewardUser(uplineOfUpline, levelPrice[level]);
                users[upline].cycleCount++;
                emit NewCycle(upline, users[upline].cycleCount);
            }

            // Reset the referral count
            users[upline].referralCount = 0;
        }
    }

    function rewardUser(address _user, uint256 _amount) internal virtual{
        users[_user].earnings += _amount;

        // Transfer the reward amount
        (bool success, ) = payable(_user).call{value: _amount}("");
        //require(success, "Transfer failed");

        // Emit an event for the earnings
        emit Earnings(_user, _amount);
    }

    function buyLevel(uint8 _newLevel) public payable {
        // require(_newLevel > users[msg.sender].partnerLevel, "Cannot downgrade or stay at the same level");
        require(_newLevel <= LAST_LEVEL, "Invalid level");

        uint256 price = levelPrice[_newLevel];
        // require(msg.value == price, "Incorrect level price");

        // Calculate earnings distribution
        address upline = users[msg.sender].upline;
        uint256 uplineEarnings = price * 10 / 100; // 10% to upline
        uint256 ownerEarnings = price - uplineEarnings;

        // Update user's partner level
        users[msg.sender].partnerLevel = _newLevel;

        // Transfer earnings to the upline
        if (upline != address(0)) {
            (bool successUpline, ) = payable(upline).call{value: uplineEarnings}("");
            // require(successUpline, "Transfer to upline failed");
            users[upline].earnings += uplineEarnings;
            emit Earnings(upline, uplineEarnings);
        }

        // Transfer remaining payment to the contract owner
        (bool successOwner, ) = payable(owner).call{value: ownerEarnings}("");
        // require(successOwner, "Transfer to owner failed");

        emit LevelUpgraded(msg.sender, _newLevel, price, uplineEarnings, ownerEarnings);
    }

    function generateReferralLink(address userAddress) public view returns (string memory) {
        uint userId = users[userAddress].id;
        return string(abi.encodePacked("https://example.com/referral/", uintToString(userId)));
    }

    function uintToString(uint v) private pure returns (string memory str) {
        if (v == 0) {
            return "0";
        }
        uint maxLen = 78; // Maximum length of uint in decimal format
        bytes memory reversed = new bytes(maxLen);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory strBytes = new bytes(i);
        for (uint j = 0; j < i; j++) {
            strBytes[j] = reversed[i - j - 1];
        }
        str = string(strBytes);
    }

    // Function to receive Ether
    receive() external payable {}

    function transactionHistory(address _user) public view returns (uint256, uint256) {
        User memory user = users[_user];
        return (user.cycleCount, user.earnings);
    }

    function getUserById(uint256 _id) public view returns (address) {
        return idToAddress[_id];
    }

    function getTotalReferralCount(address _upline) public view returns (uint256) {
        return _getTotalReferralCount(_upline);
    }

    function _getTotalReferralCount(address _upline) internal view returns (uint256) {
        uint256 totalCount = users[_upline].referralCount;

        // Traverse through each referral and recursively count their referrals

        return totalCount;
    }

    function getCurrentUplineLevel(address _user) public view returns (uint8) {
        address upline = users[_user].upline;
        
        // Check if the user has an upline
        if (upline == address(0)) {
            return 0; // Indicates no upline
        }

        // Return the partner level of the upline
        return users[upline].partnerLevel;
    }
}

contract X4Program is X3Program {
    struct User4 {
        address upline;
        uint256 id;
        uint256 earnings;
        uint8 partnerLevel;
        address[] x4FirstLine;
        address[] x4SecondLine;
        bool isX4Active;
        uint256 x4CycleCount;
    }
     X3Program public x3Program;
    event X4Registration(address indexed user, address indexed upline, uint256 userId, uint256 uplineId, uint256 fee);
    event X4CycleCompleted(address indexed user, uint256 cycleCount);
    event X4Earnings(address indexed user, uint256 amount);

    mapping(address => User4) public users4;

    constructor(address payable _x3Program){
        owner = msg.sender;
        x3Program = X3Program(_x3Program);

        users4[owner] = User4({
            upline: address(0),
            id: 1,
            earnings: 0,
            partnerLevel: 1,
            x4FirstLine: new address[](0) ,
            x4SecondLine: new address[](0) ,
            isX4Active: true,
            x4CycleCount: 0
        });

        idToAddress[1] = owner;

        // Initialize level prices
        levelPrice[1] = BASIC_PRICE;
        for (uint8 i = 2; i <= 8; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
        }
        levelPrice[9] = 1250e18;
        levelPrice[10] = 2500e18;
        levelPrice[11] = 5000e18;
        levelPrice[12] = 9900e18;
    }

    function registerUser(address _upline) public {
        require(users4[_upline].id != 0, "Upline does not exist");
        require(users4[msg.sender].id == 0, "User already registered");

        users4[msg.sender] = User4({
            upline: _upline,
            id: lastUserId,
            earnings: 0,
            partnerLevel: 1,
            x4FirstLine: new address[](0) ,
            x4SecondLine: new address[](0) ,
            isX4Active: false,
            x4CycleCount: 0
        });

        idToAddress[lastUserId] = msg.sender;
        lastUserId++;

        handleX4(msg.sender);

        emit X4Registration(msg.sender, _upline, users4[msg.sender].id, users4[_upline].id, REGISTRATION_FEE);
    }

    // Update other functions to use `users4` mapping instead of `users`

    function handleX4(address _user) internal {
        User4 storage user = users4[_user];
        if (!user.isX4Active) return;

        address upline = user.upline;
        User4 storage uplineUser = users4[upline];

        if (uplineUser.x4FirstLine.length < 2) {
            uplineUser.x4FirstLine.push(_user);
        } else if (uplineUser.x4SecondLine.length < 4) {
            uplineUser.x4SecondLine.push(_user);
        } else {
            // Handle completion of X4 cycle
            uplineUser.x4CycleCount++;
            emit X4CycleCompleted(upline, uplineUser.x4CycleCount);

            // Reward the upline of the completed cycle
            uint8 level = users4[upline].partnerLevel;
            uint256 cycleReward = levelPrice[level];
            rewardUser(upline, cycleReward);

            // Reset X4 positions
            uplineUser.x4FirstLine = new address[](0) ;
            uplineUser.x4SecondLine = new address[](0) ;
        }

        // Distribute rewards for the second line referrals
        for (uint i = 0; i < user.x4SecondLine.length; i++) {
            address referral = user.x4SecondLine[i];
            rewardUser(referral, levelPrice[user.partnerLevel]);
        }
    }

    function rewardUser(address _user, uint256 _amount) internal override {
        users4[_user].earnings += _amount;
        (bool success, ) = payable(_user).call{value: _amount}("");
        require(success, "Transfer failed");

        emit X4Earnings(_user, _amount);
    }

    function getUserInfo(address _user) public view returns (
        address, uint256, uint256, uint8, bool, uint256
    ) {
        User4 memory user = users4[_user];
        return (
            user.upline,
            user.id,
            user.earnings,
            user.partnerLevel,
            user.isX4Active,
            user.x4CycleCount
        );
    }

    // Update additional functions to work with `users4`
}