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

    event Registration(address indexed user, address indexed upline, uint256 userId, uint256 uplineId,uint256 fee,uint8 partnerLevel);
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
            passwordHash:passwordHash,
            userAddress: _upline
        });

        idToAddress[lastUserId] = _upline;
        lastUserId++;

        // Transfer registration fee to the contract owner
        payable(owner).transfer(msg.value);

        emit Registration(_upline, address(0), users[_upline].id, 0, REGISTRATION_FEE,1);
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
        handleReferral(msg.sender, _upline);

        // Transfer registration fee to the contract owner
       

        emit Registration(msg.sender, _upline, users[msg.sender].id, users[_upline].id,REGISTRATION_FEE,1);
    }

    function handleReferral(address _user, address _upline) internal {
        address uplineUser = users[_user].upline;
        if (users[_upline].referralCount < 3) {
            uint8 level = users[uplineUser].partnerLevel;
            // Reward the upline directly if they have less than 3 referrals
            rewardUser(_upline, levelPrice[level]);
        } else {
            // On the third referral, the cycle completes and the reward goes to the upline's upline
            address uplineOfUpline = users[_upline].upline;
            if (uplineOfUpline != address(0)) {
                rewardUser(uplineOfUpline, levelPrice[1]);
                users[_upline].cycleCount++;
                emit NewCycle(_upline, users[_upline].cycleCount);
            }

            // Reset the referral count
            users[_upline].referralCount = 0;
        }
    }

    function rewardUser(address _user, uint256 _amount) internal {
        users[_user].earnings += _amount;

        // Transfer the reward amount
        (bool success, ) = payable(_user).call{value: _amount}("");
       // require(success, "Transfer failed");

        // Emit an event for the earnings
        emit Earnings(_user, _amount);
    }

    function buyLevel(uint8 _newLevel) public payable {
    require(_newLevel > users[msg.sender].partnerLevel, "Cannot downgrade or stay at the same level");
    require(_newLevel <= LAST_LEVEL, "Invalid level");

    uint256 price = levelPrice[_newLevel];
    //require(msg.value == price, "Incorrect level price");

    // Calculate earnings distribution
    address upline = users[msg.sender].upline;
    uint256 uplineEarnings = price * 10 / 100; // 10% to upline
    uint256 ownerEarnings = price - uplineEarnings;

    // Update user's partner level
    users[msg.sender].partnerLevel = _newLevel;

    // Transfer earnings to the upline
    if (upline != address(0)) {
        (bool successUpline, ) = payable(upline).call{value: uplineEarnings}("");
        require(successUpline, "Transfer to upline failed");
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
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];
        }
        str = string(s);
    }

      function payUpline(address _user) public payable returns (uint256) {
        address uplineUser = users[_user].upline;

        if (uplineUser == address(0)) {
            return 0;
        }

        if (users[uplineUser].referralCount >= 2) {
            uint8 level = users[uplineUser].partnerLevel;
            uint256 reward = levelPrice[level];
            //require(address(this).balance >= reward, "Insufficient contract balance");
            rewardUser(uplineUser, reward);

            users[uplineUser].cycleCount++;
            emit NewCycle(uplineUser, users[uplineUser].cycleCount);
            users[uplineUser].referralCount = 0;
        } else {
             
           users[uplineUser].referralCount++;
       // Transfer the reward amount to the user's upline
          // (bool success, ) = payable(uplineUser).call{value: msg.value}("");
           //require(success, "Transfer failed");
          // users[uplineUser].earnings += msg.value;
          // emit Earnings(uplineUser, msg.value);
          // emit NewReferral(_user, uplineUser);
       

    }
    }

    // Function to receive Ether
    receive() external payable {}


    function getUserInfo(address _user) public view returns (
        address, uint256, uint256, uint256, uint256, uint256, string memory, string memory, string memory, string memory, address
    ) {
        User memory user = users[_user];
        return (
            user.upline,
            user.id,
            user.referralCount,
            user.cycleCount,
            user.earnings,
            user.partnerLevel,
            user.firstName,
            user.lastName,
            user.profilePic,
            user.email,
            user.userAddress
        );
    }

    function transactionHistory(address _user) public view returns (uint256, uint256) {
        User memory user = users[_user];
        return (user.cycleCount, user.earnings);
    }

    function getUserById(uint256 _id) public view returns (address) {
        return idToAddress[_id];
    }

    function getLevelPrice(uint8 _level) public view returns (uint256) {
        require(_level >= 1 && _level <= LAST_LEVEL, "Invalid level");
        return levelPrice[_level];
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