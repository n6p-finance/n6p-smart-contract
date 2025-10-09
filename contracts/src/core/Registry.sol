// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

interface IVaultRegistryView {
    function token() external view returns (address);
    function apiVersion() external view returns (string memory);
    function governance() external view returns (address);
}

interface IVaultInitialize {
    // Initialization (replaces Vyper initialize external)
    function initialize(
        address token,
        address governance,
        address rewards,
        string calldata name,
        string calldata symbol,
        address guardian,
        address management
    ) external;
}

contract Registry {
    // releases
    uint256 public numReleases;
    mapping(uint256 => address) public releases;

    // token => vaults count
    mapping(address => uint256) public numVaults;
    mapping(address => mapping(uint256 => address)) public vaults; // token => id => vault

    // tokens index
    mapping(uint256 => address) public tokens; // index => token
    uint256 public numTokens;
    mapping(address => bool) public isRegistered; // token => included

    // governance (2-step)
    address public governance;
    address public pendingGovernance;

    // tagging
    mapping(address => string) public tags; // vault => tag
    mapping(address => bool) public banksy; // tagger => allowed

    event NewRelease(uint256 indexed release_id, address template, string api_version);
    event NewVault(address indexed token, uint256 indexed vault_id, address vault, string api_version);
    event NewExperimentalVault(address indexed token, address indexed deployer, address vault, string api_version);
    event NewGovernance(address governance);
    event VaultTagged(address vault, string tag);

    constructor() {
        governance = msg.sender;
    }

    // Governance
    function setGovernance(address _gov) external {
        require(msg.sender == governance, "unauthorized");
        pendingGovernance = _gov;
    }
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "unauthorized");
        governance = msg.sender;
        emit NewGovernance(msg.sender);
    }

    // Views
    function latestRelease() external view returns (string memory) {
        require(numReleases > 0, "no release");
        return IVaultRegistryView(releases[numReleases - 1]).apiVersion();
    }
    function latestVault(address token) external view returns (address) {
        require(numVaults[token] > 0, "no vault for token");
        return vaults[token][numVaults[token] - 1];
    }

    // Release management vault version
    function newRelease(address vault) external {
        require(msg.sender == governance, "unauthorized");
        uint256 release_id = numReleases;
        if (release_id > 0) {
            string memory prev = IVaultRegistryView(releases[release_id - 1]).apiVersion();
            string memory next = IVaultRegistryView(vault).apiVersion();
            require(keccak256(bytes(prev)) != keccak256(bytes(next)), "same api version");
        }
        releases[release_id] = vault;
        numReleases = release_id + 1;
        emit NewRelease(release_id, vault, IVaultRegistryView(vault).apiVersion());
    }

    // EIP-1167 minimal proxy clone
    function _clone(address implementation) internal returns (address instance) {
        bytes20 targetBytes = bytes20(implementation);
        assembly {
            let clone := mload(0x40) // Get free memory pointer
            mstore(clone, 0x3d602d80600a3d3981f3)
            mstore(add(clone, 0x14), 0x363d3d373d3d3d363d73)
            mstore(add(clone, 0x28), targetBytes) // Address of the implementation contract
            mstore(add(clone, 0x3c), 0x5af43d82803e903d91602b57fd5bf3)
            instance := create(0, clone, 0x37) // Deploys code stored in memory clone
        }
        require(instance != address(0), "clone failed");
    }

    function _newProxyVault(
        address token,
        address _governance,
        address rewards,
        address guardian,
        string memory name,
        string memory symbol,
        uint256 releaseTarget
    ) internal returns (address) {
        address release = releases[releaseTarget];
        require(release != address(0), "unknown release");
        address vault = _clone(release);
        // Match Vyper default for management (msg.sender), which would be Registry in that context
        IVaultInitialize(vault).initialize(token, _governance, rewards, name, symbol, guardian, address(this));
        return vault;
    }

    function _registerVault(address token, address vault) internal {
        uint256 vault_id = numVaults[token];
        if (vault_id > 0) {
            string memory prev = IVaultRegistryView(vaults[token][vault_id - 1]).apiVersion();
            string memory next = IVaultRegistryView(vault).apiVersion();
            require(keccak256(bytes(prev)) != keccak256(bytes(next)), "same api version");
        }
        vaults[token][vault_id] = vault;
        numVaults[token] = vault_id + 1;
        if (!isRegistered[token]) {
            isRegistered[token] = true;
            tokens[numTokens] = token;
            numTokens += 1;
        }
        emit NewVault(token, vault_id, vault, IVaultRegistryView(vault).apiVersion());
    }

    function newVault(
        address token,
        address guardian,
        address rewards,
        string calldata name,
        string calldata symbol,
        uint256 releaseDelta
    ) external returns (address) {
        require(msg.sender == governance, "unauthorized");
        uint256 releaseTarget = numReleases - 1 - releaseDelta; // underflow if none
        address vault = _newProxyVault(token, msg.sender, rewards, guardian, name, symbol, releaseTarget);
        _registerVault(token, vault);
        return vault;
    }

    function newExperimentalVault(
        address token,
        address _governance,
        address guardian,
        address rewards,
        string calldata name,
        string calldata symbol,
        uint256 releaseDelta
    ) external returns (address) {
        uint256 releaseTarget = numReleases - 1 - releaseDelta; // underflow if none
        address vault = _newProxyVault(token, _governance, rewards, guardian, name, symbol, releaseTarget);
        emit NewExperimentalVault(token, msg.sender, vault, IVaultRegistryView(vault).apiVersion());
        return vault;
    }

    function endorseVault(address vault, uint256 releaseDelta) external {
        require(msg.sender == governance, "unauthorized");
        require(IVaultRegistryView(vault).governance() == msg.sender, "not governed");
        uint256 releaseTarget = numReleases - 1 - releaseDelta; // underflow if none
        string memory api = IVaultRegistryView(releases[releaseTarget]).apiVersion();
        require(keccak256(bytes(IVaultRegistryView(vault).apiVersion())) == keccak256(bytes(api)), "not target release");
        _registerVault(IVaultRegistryView(vault).token(), vault);
    }

    function setBanksy(address tagger, bool allowed) external {
        require(msg.sender == governance, "unauthorized");
        banksy[tagger] = allowed;
    }

    function tagVault(address vault, string calldata tag) external {
        if (msg.sender != governance) {
            require(banksy[msg.sender], "not banksy");
        }
        tags[vault] = tag;
        emit VaultTagged(vault, tag);
    }
}


