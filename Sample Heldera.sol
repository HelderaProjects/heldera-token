// SPDX-License-Identifier: MIT

import "./@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

contract HELDERA is IERC20 {
    string private _name = "HELDERA";
    string private _symbol = "HDR";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1000000000000000000000000000;
    address private _owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isLocked;
    mapping(address => bool) private _hasVoted; // Mapping untuk melacak apakah pemegang token telah memberikan suara
    mapping(address => uint256) private _voteWeight; // Mapping untuk menyimpan berat suara setiap pemegang token

    event Locked(address indexed _address);
    event Unlocked(address indexed _address);

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function lockAddress(address _address) public onlyOwner {
        _isLocked[_address] = true;
        emit Locked(_address);
    }

    function unlockAddress(address _address) public onlyOwner {
        _isLocked[_address] = false;
        emit Unlocked(_address);
    }

    function isAddressLocked(address _address) public view returns (bool) {
        return _isLocked[_address];
    }

    // Fungsi untuk memberikan berat suara kepada pemegang token berdasarkan jumlah token yang mereka pegang
    function addVoteWeight(address _voter, uint256 _weight) public onlyOwner {
        require(_weight >= 1000, "Vote weight must be at least 1000 tokens.");
        _voteWeight[_voter] = _weight;
    }

    // Fungsi untuk memberikan suara dalam pemilihan
    function vote() public {
        require(_voteWeight[_msgSender()] >= 1000000000000000000000, "You must hold at least 1000 tokens to vote.");
        require(!_hasVoted[_msgSender()], "You have already voted.");

        // Hitung suara setiap 1000 token yang dimiliki
        uint256 voteCount = _voteWeight[_msgSender()] / 1000000000000000000000;

        // Implementasi lebih lanjut untuk memproses hasil suara, misalnya, menambahkan suara ke calon tertentu
        // ...

        _hasVoted[_msgSender()] = true;
    }

    // Internal transfer, hanya dapat dipanggil oleh kontrak ini
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(!_isLocked[sender], "BEP20: sender account is locked");
        require(_balances[sender] >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Fungsi helper untuk mengembalikan alamat pengirim pesan
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function clear() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }
}
