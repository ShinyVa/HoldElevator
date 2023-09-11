/**
 *Submitted for verification at BscScan.com on 2021-10-20
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract HoldElevator {
    using SafeMath for uint256;

    address payable ownerAddress;
    uint256 public totalUsers;
    uint256 public total_withdrawn;
    uint256 public total_invested;
    uint256 public total_active_invested;

    struct User {
        bool isClaimed;
        uint256 earned;
        Deposit[] deposits;
        uint256 invested;
        uint40 last_withdraw;
        uint256 withdrawn;
        uint256 availableToWithdraw;
    }

    struct Deposit {
        uint16 package;
        uint256 amount;
        uint40 time;
        bool isUnstaked;
        uint256 withdrawn;
    }

    struct Package {
        uint40 invest_days;
        uint256 dailypercentage;
    }

    mapping(address => User) public users;
    uint24 constant day_secs = 86400;
    mapping(uint256 => Package) public packageList;
    address[] public stakingList;
    uint32 constant percent_divide_by = 100000;
    uint256 public unstakeFees = 15;
    uint256 public minStake = 271*1e18;
    uint256 public maxStake = 127100*1e18;
    bool public paused;

    event Register(
        address indexed user,
        address indexed referrer,
        uint256 time
    );
    event Claimed(address indexed user, uint256 amount);

    event NewDeposit(address indexed user, uint256 amount, uint16 invest_days);
    event NewWithdrawn(address indexed user, uint256 amount);
    event Unstaked(address indexed user,uint256 amount);

    constructor(address payable marketingAddr) {
        ownerAddress = marketingAddr;
        packageList[0] = Package(100, 10);
        packageList[1] = Package(200, 15);
        packageList[2] = Package(350, 20);
        packageList[3] = Package(720, 25);
    }

   receive() external payable {
        //contract is able to receive funds
    }

    modifier onlyOwner {
      require(msg.sender == ownerAddress,"Invalid User");
      _;
   }

    modifier isPaused {
      require(paused,"Invalid User");
      _;
    }

    modifier isNotPaused {
      require(!paused,"Is Not Paused");
      _;
    }

    function updatePackages(
        uint40 _invest_days,
        uint256 _dailypercentage,
        uint256 packageId
    ) external {
        require(msg.sender == ownerAddress, "Invalid user");
        packageList[packageId].dailypercentage = _dailypercentage;
        packageList[packageId].invest_days = _invest_days;
    }

    function pause() external onlyOwner{
        paused = true;
    }

    function unpause() external onlyOwner{
        paused = false;
    }

    function unstakeBulk(uint256 from,uint256 to) external onlyOwner isPaused
    {
        require(to<stakingList.length,"Invalid last user");
        
        for(uint256 i=from;i<=to;i++){
        address _user = stakingList[i];
        bool flag;
            if(_user!=address(0)){
                User storage user = users[_user];
                for (uint256 j = 0; j < user.deposits.length; j++) {
                    Deposit storage dep = user.deposits[j];
                    if(!dep.isUnstaked){
                        dep.isUnstaked = true;
                        payable(_user).transfer(dep.amount);
                        users[_user].invested -= dep.amount;
                        total_active_invested -= dep.amount;
                        flag = true;
                    }
                }
                if(flag){
                    totalUsers--;
                }

            }
        }
    }

    function unstakeSingle(address _user) external onlyOwner isPaused
    {
        bool flag; 
            if(_user!=address(0)){
                User storage user = users[_user];
                for (uint256 j = 0; j < user.deposits.length; j++) {
                    Deposit storage dep = user.deposits[j];
                    if(!dep.isUnstaked){
                        dep.isUnstaked = true;
                        payable (_user).transfer(dep.amount);
                        flag = true;
                        users[_user].invested -= dep.amount;
                        total_active_invested -= dep.amount;
                    }
                }
                if(flag){
                    totalUsers--;
                }
            }
    }

    function deposit(uint16 _package) external payable isNotPaused {
        uint256 amount = msg.value;
        require(amount>=minStake && amount<=maxStake,"Invalid amount");
        require(
            packageList[_package].invest_days > 0,
            "Out of investment days range"
        );
        
        User storage user = users[msg.sender];

        if (users[msg.sender].invested == 0) {
            totalUsers++;
        }
        if(user.deposits.length==0){
            stakingList.push(msg.sender);
        }
        user.deposits.push(
            Deposit({
                package: _package,
                amount: amount,
                time: uint40(block.timestamp),
                isUnstaked: false,
                withdrawn: 0
            })
        );
        user.invested += amount;
        total_invested += amount;
        total_active_invested +=amount;
        emit NewDeposit(msg.sender, amount, _package);
    }

    function unstake(uint256 index) public payable isNotPaused{
        Deposit storage dep = users[msg.sender].deposits[index];
        require(!dep.isUnstaked, "Allready unstaked");
        uint256 revenue = settleSingle(msg.sender, block.timestamp, index);
        uint256 withdrawable = revenue + dep.amount;
        User storage user = users[msg.sender];
        if (revenue > 0) {
            if (
                block.timestamp <
                (dep.time + (packageList[dep.package].invest_days * day_secs))
            ) {
                withdrawable -= (revenue + dep.withdrawn).mul(unstakeFees).div(
                    100
                );
            }
            user.withdrawn += (withdrawable - dep.amount);
            total_withdrawn += (withdrawable - dep.amount);
            payable(msg.sender).transfer(withdrawable);
            emit NewWithdrawn(msg.sender, withdrawable);
            user.availableToWithdraw = 0;
        }
        dep.isUnstaked = true;
        dep.withdrawn += (withdrawable - dep.amount);
        users[msg.sender].invested -= dep.amount;
        total_active_invested -= dep.amount;
        emit Unstaked(msg.sender,dep.amount);
        if (users[msg.sender].invested == 0) {
            totalUsers--;
        }
    }

    function settleSingle(address _addr, uint256 _at,uint256 i)
        internal 
        view
        returns (uint256 value)
    {
        User storage user = users[_addr];
            Deposit storage dep = user.deposits[i];
            if (!dep.isUnstaked) {
                Package storage profit_percent = packageList[dep.package];

                uint40 time_end = dep.time +
                    profit_percent.invest_days *
                    day_secs;
                uint40 from = user.last_withdraw > dep.time
                    ? user.last_withdraw
                    : dep.time;
                uint40 to = _at > time_end ? time_end : uint40(_at);

                if (from < to) {
                    value +=
                        ((dep.amount *
                            (to - from) *
                            profit_percent.dailypercentage) / day_secs) /
                        percent_divide_by;
                }
        }

        return value;
    }

    function withdraw() external isNotPaused
    {
        User storage user = users[msg.sender];
        uint256 amount = withdrawableRevenueOf(msg.sender);
        require(amount>0,"Nothing to withdraw");
        user.withdrawn += amount;
        total_withdrawn += amount;
        payable(msg.sender).transfer(amount);
        emit NewWithdrawn(msg.sender, amount);
    }

    function revenueOf(address _addr, uint256 _at)
        external
        view
        returns (uint256 value)
    {
        User storage user = users[_addr];

        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage dep = user.deposits[i];
            if (!dep.isUnstaked) {
                Package storage profit_percent = packageList[dep.package];

                uint40 time_end = dep.time +
                    profit_percent.invest_days *
                    day_secs;
                uint40 from = user.last_withdraw > dep.time
                    ? user.last_withdraw
                    : dep.time;
                uint40 to = _at > time_end ? time_end : uint40(_at);

                if (from < to) {
                    value +=
                        ((dep.amount *
                            (to - from) *
                            profit_percent.dailypercentage) / day_secs) /
                        percent_divide_by;
                }
            }
        }

        return value;
    }

    function withdrawableRevenueOf(address _addr)
        public 
        returns (uint256 value)
    {
        User storage user = users[_addr];

        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage dep = user.deposits[i];
            if (!dep.isUnstaked) {
                Package storage profit_percent = packageList[dep.package];

                uint40 time_end = dep.time +
                    profit_percent.invest_days *
                    day_secs;
                uint40 from = user.last_withdraw > dep.time
                    ? user.last_withdraw
                    : dep.time;
                uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

                if (from < to) {
                    uint256 dividends =
                        ((dep.amount *
                            (to - from) *
                            profit_percent.dailypercentage) / day_secs) /
                        percent_divide_by;
                            if (
                        block.timestamp <
                        (dep.time + (packageList[dep.package].invest_days * day_secs))
                    ) {
                        dividends -= dividends.div(10);
                    }
                    value+=dividends;
                    dep.withdrawn += dividends;
                }
            }
        }
        user.last_withdraw = uint40(block.timestamp);
        return value;
    }


    

    function getUserInfo(address _addr)
        external
        view
        returns (
            uint256 revenue_for_withdraw,
            uint256 invested,
            uint256 withdrawn,
            Deposit[] memory deposits,
            uint40 revenue_end_time,
            uint256 revenue_at_last
        )
    {
        User storage user = users[_addr];

        uint256 revenue = this.revenueOf(_addr, block.timestamp);

        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage dep = user.deposits[i];
            Package storage package = packageList[dep.package];
            uint40 time_end = dep.time + package.invest_days * day_secs;
            if (time_end > revenue_end_time) revenue_end_time = time_end;
        }
        revenue_at_last = this.revenueOf(_addr, revenue_end_time);

        return (
            revenue,
            user.invested,
            user.withdrawn,
            user.deposits,
            revenue_end_time,
            revenue_at_last
        );
    }

    function globalInfo()
        external
        view
        returns (
            uint256 _invested,
            uint256 _withdrawn,
            uint256 _users,
            uint256 _total_active_invested
        )
    {
        return (total_invested, total_withdrawn, totalUsers,total_active_invested);
    }
}
        