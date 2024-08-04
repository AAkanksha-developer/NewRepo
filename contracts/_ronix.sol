// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow

 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 library SafeMath {
     function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c =a+b;
        require(c>=a,"add overflow");
        return c;
     }
     function sub(uint256 a, uint256 b) internal pure returns (uint256){
        require(b<=a,"sub underflow");
        return a-b;
     }
     function mul(uint256 a, uint256 b) internal pure returns (uint256){
        if(a==0) return 0;
        uint256 c =a*b;
        require(c/a==b,"mul overflow");
        return c;
     }
     function div(uint256 a, uint256 b) internal pure returns (uint256){
       require(b>0,"div by zero");
        uint256 c =a/b;
        return c;
     }
     function mod(uint256 a, uint256 b) internal pure returns (uint256){
        require(b>0,"mod by zero");
        return a%b;
     }
 }

 interface IERC20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
 }

 library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size:= extcodesize(account)}
        return size>0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value : amount}("");
        require(success, "Address : unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address : low level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address : low level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address : insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return verifyCallResultFromTarget( success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address : low level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget( success, returndata, errorMessage);
    }
    function verifyCallResultFromTarget( bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {

        if(success) {
            if(returndata.length==0) {
                return returndata;
            }else {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
        }else {
            if(returndata.length>0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }else {
                revert(errorMessage);
            }
        }
    }
 }

 library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
     }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
     }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value==0)||(token.allowance(address(this), spender)==0), "SafeERC20 : approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
     }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
     }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
     }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20 : low level call failed");
        if(returndata.length>0) {
            require(abi.decode(returndata, (bool)), "SafeERC20 : ERC20 operation did not succeed");
         }
     }
 }

 abstract contract Proxy {
    function _delegate(address implementation) internal{
         assembly {
            calldatacopy(0, 0, calldatasize())
            
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
        
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    function _implementation() internal virtual view returns (address);
    function _fallback() internal {
       
        _delegate(_implementation());
    }

    fallback () payable external {
        _fallback();
    }

    receive () payable external {
        _fallback();
    }

 }
 
 abstract contract Ronx is Proxy {
    address public impl;
    address public contractOwner;
    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "only contract owner can call this function");
        _;
    }
    modifier onlyImpl() {
        require(msg.sender == impl, "only implementation can call this function");
        _;
    }
    constructor(address _impl) {
        impl = _impl;
        contractOwner = msg.sender;
    }
    function update(address _impl) external onlyContractOwner {
        impl = _impl;
    }
    function removeOwnership()public onlyContractOwner {
        contractOwner = address(0);
    }
    
    function _implementation() internal override view returns (address) {
        return impl;
    }
 }

 contract RonxBasic {
    address public impl;
    address public contractOwner;

    struct User{
        uint id;
        address referrer;
        string firstName;
        string lastName;
        string email;
        bytes32 passwordHash;
        string profilePicture;
        uint  userId;
        uint referrerId;
        uint transactionFee;
        uint8 levelId;
        string referralLink;
        uint partnersCount;
        uint totalTransactions;
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => X3) x3Matrix;
        
    }
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
        mapping(uint => uint) referralsReinvestCounts; // referrals id => reinvestCount
        mapping(uint => uint) referralsBalances; // referrals id => balance
    }
    uint8 public LAST_LEVEL;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 
    uint public lastUserId;
    address public id1;
    address public multisig;
    
    mapping(uint8 => uint) public levelPrice;

    IERC20 public depositToken;
    
    uint public BASIC_PRICE;

    bool public locked;
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedBUSDReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraBUSDDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event Transaction( address indexed user,uint indexed userId, uint transactionAmount, uint8 levelId,uint timestamp     
    );
 }

 contract RonxMatrix is RonxBasic {
    using SafeERC20 for  IERC20;
    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "onlyOwner"); 
        _; 
 }
    modifier onlyUnlocked() { 
        require(!locked || msg.sender == contractOwner); 
        _; 
    }
    function init(address _ownerAddress, address _multisig, IERC20 _depositTokenAddress)public onlyContractOwner{
        BASIC_PRICE =  5e18;
        LAST_LEVEL = 12;
        levelPrice[1] = BASIC_PRICE;
        for (uint8 i = 2; i <= 8; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        levelPrice[9] = 1250e18;
        levelPrice[10] = 2500e18;
        levelPrice[11] = 5000e18;
        levelPrice[12] = 9900e18;

        id1=_ownerAddress;
        User storage user = users[ _ownerAddress];
        user.id = 1;
        user.referrer = address(0);
        user.partnersCount = 0;
        user.referralLink = generateReferralLink(_ownerAddress);
        idToAddress[1] = _ownerAddress;
         for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[_ownerAddress].activeX3Levels[i] = true;
        }
        lastUserId = 2;
        depositToken = _depositTokenAddress;
        multisig = _multisig;
        locked = true;

    }
    function changeLock() external onlyContractOwner() {
        locked = !locked;
    }
    fallback() external {
        if(msg.data.length == 0) {
            return registration(msg.sender, id1, "", "", "", "", "");
        }
        
        registration(msg.sender, bytesToAddress(msg.data), "", "", "", "", "");
    }

    function registrationExt(
        address referrerAddress,
        string memory firstName,
        string memory lastName,
        string memory email,
        string memory password,
        string memory profilePicture
    ) external onlyUnlocked() {
        registration(msg.sender, referrerAddress, firstName, lastName, email, password, profilePicture);
    }

     function registrationFor(
        address userAddress,
        address referrerAddress,
        string memory firstName,
        string memory lastName,
        string memory email,
        string memory password,
        string memory profilePicture
    ) external onlyUnlocked()  {
        registration(userAddress, referrerAddress, firstName, lastName, email, password, profilePicture);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external onlyUnlocked() {
        _buyNewLevel(msg.sender, matrix, level);
    }
    function buyNewLevelFor(address userAddress, uint8 matrix, uint8 level) external onlyUnlocked() {
        _buyNewLevel(userAddress, matrix, level);
    }
    function _buyNewLevel(address _userAddress, uint8 matrix, uint8 level) internal {
        require(isUserExists(_userAddress), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");

        depositToken.safeTransferFrom(msg.sender, address(this), levelPrice[level]);
        // require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
          require(users[_userAddress].activeX3Levels[level-1], "buy previous level first");
          require(!users[_userAddress].activeX3Levels[level], "level already activated");

            if (users[_userAddress].x3Matrix[level-1].blocked) {
                users[_userAddress].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(_userAddress, level);
            users[_userAddress].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[_userAddress].activeX3Levels[level] = true;
            updateX3Referrer(_userAddress, freeX3Referrer, level);
            users[_userAddress].totalTransactions++;
            emit Upgrade(_userAddress, freeX3Referrer, 1, level);
        }

    }
    function registerUser(
        address referrerAddress,
        string memory firstName,
        string memory lastName,
        string memory email,
        string memory password,
        string memory profilePicture
    ) external {
        registration(msg.sender, referrerAddress, firstName, lastName, email, password, profilePicture);
    }

    function registration(
        address userAddress,
        address referrerAddress,
        string memory firstName,
        string memory lastName,
        string memory email,
        string memory password,
        string memory profilePicture
    ) private {
        // Deduct 25 BUSD from the sender's account
        uint256 transactionFee = (BASIC_PRICE * 2) + 5;
        uint8 initialLevel = 1;
        depositToken.safeTransferFrom(msg.sender, address(this), (BASIC_PRICE*2)+5);

        require(!isUserExists(userAddress), "User already exists");
        //require(isUserExists(referrerAddress), "Referrer does not exist");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "Address must be an EOA");

        lastUserId++;
        
        User storage user = users[userAddress];
        user.id = lastUserId;
        user.referrer = referrerAddress;
        user.partnersCount = 0;
        user.firstName = firstName;
        user.lastName = lastName;
        user.email = email;
        user.passwordHash = keccak256(abi.encodePacked(password));
        user.profilePicture = profilePicture;
        user.referralLink = generateReferralLink(userAddress); 
        user.activeX3Levels[initialLevel] = true;// Initialize the first level
        user.totalTransactions = 1; 
        
        idToAddress[lastUserId] = userAddress;
        userIds[lastUserId] = userAddress;

        users[referrerAddress].partnersCount++;
        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        users[freeX3Referrer].x3Matrix[1].referrals.push(userAddress);
        
        updateX3Referrer(userAddress, freeX3Referrer,  initialLevel);
       

        

        emit Registration(userAddress, referrerAddress, user.id, users[referrerAddress].id);
        logTransaction(userAddress, transactionFee, initialLevel);
    }
     function generateReferralLink(address userAddress) private pure returns (string memory) {
        return string(abi.encodePacked("https://example.com/referral/", toAsciiString(userAddress)));
    }
    function toAsciiString(address x) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
     function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
         users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
         users[referrerAddress].totalTransactions++;
         if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendBUSDDividends(referrerAddress, userAddress, 1, level);
        }
        
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }
         if (referrerAddress != id1) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
             
            users[referrerAddress].totalTransactions++; // Increment total transactions
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendBUSDDividends(id1, userAddress, 1, level);
            users[id1].x3Matrix[level].reinvestCount++;
            emit Reinvest(id1, address(0), userAddress, 1, level);
        }
    }
   
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }
     function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked);
    }
      function findBUSDReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address,bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedBUSDReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
      }
      function sendBUSDDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findBUSDReceiver(userAddress, _from, matrix, level);

        depositToken.safeTransfer(receiver, levelPrice[level]);
        // if (!address(uint160(receiver)).send(levelPrice[level])) {
        //     return address(uint160(receiver)).transfer(address(this).balance);
        // }
        
        if (isExtraDividends) {
            emit SentExtraBUSDDividends(_from, receiver, matrix, level);
        }
    }
    
     function withdrawLostTokens(address tokenAddress) public onlyContractOwner {
        require(tokenAddress != address(depositToken), "cannot withdraw deposit token");
        if (tokenAddress == address(0)) {
           address payable multisigPayable = payable(multisig);
           multisigPayable.transfer(address(this).balance);
        } else {
            IERC20(tokenAddress).transfer(multisig, IERC20(tokenAddress).balanceOf(address(this)));
            //IERC20 token = IERC20(tokenAddress);
            //token.safeTransfer(multisig, token.balanceOf(address(this)));
        }
    }
     function logTransaction(
        address user,
        uint amount,
        uint8 level
    ) private {
        emit Transaction(user, users[user].id, amount, level, block.timestamp);
    }

function getTransactionHistory(
    address user
) public view returns (
    address,
    uint,
    uint8[] memory levels,
    uint[] memory timestamps,
    uint totalTransactions,
    uint[] memory cycles
) {
    uint8[] memory userLevels = new uint8[](LAST_LEVEL);
    uint[] memory userTimestamps = new uint[](LAST_LEVEL);
    uint[] memory userCycles = new uint[](LAST_LEVEL);

    for (uint8 i = 1; i <= LAST_LEVEL; i++) {
        if (users[user].activeX3Levels[i]) {
            userLevels[i - 1] = i;
            userTimestamps[i - 1] = block.timestamp; // Replace with actual timestamp logging if available
            userCycles[i - 1] = users[user].x3Matrix[i].reinvestCount;
        }
    }
    return (user, users[user].id, userLevels, userTimestamps, users[user].totalTransactions, userCycles);
  }
 }