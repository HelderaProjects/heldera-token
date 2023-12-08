// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract HELDERA is IERC20, Ownable {
    using SafeMath for uint256;
    string private _name = "HELDERA";
    string private _symbol = "HDR";
    uint256 private constant TOTAL_SUPPLY = 1000000000000000000000000000;
    uint8 private constant DECIMALS = 18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address[] private _coreFounders = [
        0xc0a88D89571719F8655C6FF3e40d7540492b4141,
        0xa6BC3B749920a770866d6C2d6D8d1850EBdB43e6,
        0x184b4f4950E785B2F8766939022B49E8250F0f44,
        0x9faEF26225d7D0C4D55981E80B8C45e539cACFEa,
        0x4Ff7ffc4842d1539c9E7d5ab2B99CD0638A68386
    ];

    uint256 public constant FOUNDERS_PERCENTAGE_PER_YEAR = 20;
    uint256 public constant MAX_FOUNDERS_PERCENTAGE = 1;
    uint256 public constant DISTRIBUTION_PERIOD = 5;
    uint256 public constant LOCK_DURATION = 2;

    mapping(address => uint256) private _foundersAllocations;
    mapping(address => uint256) private _foundersLockExpiry;
    mapping(address => uint256) private _lastDistributionTimestamp;

    event FounderTokensAllocated(address indexed founder, uint256 amount, uint256 lockDuration);

       constructor() Ownable(msg.sender) {
        uint256 founderAllocation = (TOTAL_SUPPLY * MAX_FOUNDERS_PERCENTAGE) / 100;
        for (uint256 i = 0; i < _coreFounders.length; i++) {
            _foundersAllocations[_coreFounders[i]] = founderAllocation;
            _foundersLockExpiry[_coreFounders[i]] = block.timestamp + (LOCK_DURATION * 365 days);
            _lastDistributionTimestamp[_coreFounders[i]] = block.timestamp;
            emit FounderTokensAllocated(_coreFounders[i], founderAllocation, LOCK_DURATION);
        }
        _balances[owner()] = TOTAL_SUPPLY - (_coreFounders.length * founderAllocation);
        emit Transfer(address(0), owner(), TOTAL_SUPPLY - (_coreFounders.length * founderAllocation));
    }

    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_foundersLockExpiry[msg.sender] <= block.timestamp, "Tokens are still locked for founder");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(_foundersLockExpiry[sender] <= block.timestamp, "Tokens are still locked for founder");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function unlockFounderTokens() public {
        require(_foundersAllocations[msg.sender] > 0, "Caller is not a founder");
        require(block.timestamp >= _foundersLockExpiry[msg.sender], "Tokens are still locked");
        _foundersLockExpiry[msg.sender] = 0;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function distributeFounderTokens() external onlyOwner {
        for (uint256 i = 0; i < _coreFounders.length; i++) {
            address founder = _coreFounders[i];
            require(block.timestamp >= _lastDistributionTimestamp[founder] + 365 days, "Distribusi belum waktunya");

            uint256 founderAllocation = _foundersAllocations[founder];
            uint256 distributionAmount = founderAllocation.mul(FOUNDERS_PERCENTAGE_PER_YEAR).div(100);

            require(_balances[address(this)] >= distributionAmount, "Saldo kontrak tidak cukup untuk distribusi");

            _balances[address(this)] = _balances[address(this)].sub(distributionAmount);
            _balances[founder] = _balances[founder].add(distributionAmount);

            _lastDistributionTimestamp[founder] = block.timestamp;

            emit Transfer(address(this), founder, distributionAmount);
        }
    }

    function renounceOwnership() public onlyOwner override {
        super.renounceOwnership();
    }
}
