// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20Interface {
    function totalSupply() external view returns (uint);

    function balanceOf(address tokenOwner) external view returns (uint balance);

    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(
        address tokenOwner,
        address spender
    ) external view returns (uint remaining);

    function approve(
        address spender,
        uint tokens
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint tokens
    );
}

contract EtherNova is ERC20Interface {
    string public name = "EtherNova";
    string public symbol = "ENO";
    int public decimal = 0;
    uint public override totalSupply;

    address public founder;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function balanceOf(
        address tokenOwner
    ) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(
        address to,
        uint tokens
    ) public virtual override returns (bool success) {
        require(
            balances[msg.sender] >= tokens,
            "You have insuffficient balance"
        );
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function allowance(
        address tokenOwner,
        address spender
    ) public view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(
        address spender,
        uint tokens
    ) public override returns (bool success) {
        require(balances[msg.sender] >= tokens, "Insufficient balance");
        require(tokens > 0, "Cannot send zero tokens");

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint tokens
    ) public virtual override returns (bool success) {
        require(
            allowed[from][msg.sender] >= tokens,
            "allowed token amount is less"
        );
        require(balances[from] >= tokens, "Insufficient token balance!");
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;

        emit Transfer(from, to, tokens);
        return true;
    }
}

contract NovaICO is EtherNova {
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.001 ether; // 1 ETH = 1000 ENO {EtherNova}
    uint public hardCap = 200 ether; // hardcap = max amount of funds to be raised 200 ether ie 2000ENO
    uint public raisedAmount;
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 432000; //ico ends in 5 days
    uint public tokenTradeStart = saleEnd + 604800; //can sell ENO 1 week after end of ico

    enum State {
        beforeStart,
        running,
        afterEnd,
        halted
    }
    State public icoState;

    constructor(address payable _deposit) {
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function halt() public onlyAdmin {
        icoState = State.halted;
    }

    function resume() public onlyAdmin {
        icoState = State.running;
    }

    function changeDepositeAddress(
        address payable newDeposit
    ) public onlyAdmin {
        deposit = newDeposit;
    }

    function getCurrentState() public view returns (State) {
        if (icoState == State.halted) {
            return State.halted;
        } else if (block.timestamp < saleStart) {
            return State.beforeStart;
        } else if (block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return State.running;
        } else {
            return State.afterEnd;
        }
    }

    event Invest(address investor, uint value, uint tokens);

    function invest() public payable returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.running);

        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);

        uint tokens = msg.value / tokenPrice;

        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        deposit.transfer(msg.value);
        emit Invest(msg.sender, msg.value, tokens);

        return true;
    }

    receive() external payable {
        invest();
    }

    function transfer(
        address to,
        uint tokens
    ) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart);
        super.transfer(to, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint tokens
    ) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart);
        super.transferFrom(from, to, tokens);
        return true;
    }
}
