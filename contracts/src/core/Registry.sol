// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";

interface IVaultRegistryView {
    function token() external view returns (address);
    function apiVersion() external view returns (string memory);
    function governance() external view returns (address);
}

interface IVaultInitialize {
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

/**
 * @title Registry Napfi
 * @notice Registry manages releases, vaults, tagging — and adds a versioned Agenda system
 *         for each vault/strategy so creators and governance can store and evolve strategy agendas.
 *
 * Key Agenda notes:
 * - Agendas are versioned (appended) and immutable once created (content cannot be overwritten).
 * - Authorized actors (vault governance, vault creator, registry governance) can create and toggle activity.
 * - Agendas support title, freeform content, optional IPFS hash, a light riskLevel, and tags.
 */
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

    // mapping vault -> creator (deployer)
    mapping(address => address) public vaultCreator;

    // Agenda system
    struct Agenda {
        string title;        // human readable short title
        string content;      // full content or JSON (freeform)
        string ipfsHash;     // optional pointer to IPFS / Arweave / offchain content
        string[] metaTags;   // small list of tags (e.g., ["yield","leverage"])
        uint8 riskLevel;     // 0..255 (Napfi lightweight risk score)
        uint256 timestamp;   // creation time
        address author;      // who created this agenda (creator or governance)
        bool active;         // whether this agenda version is active (allows toggling)
    }

    // vault => Agenda[]
    mapping(address => Agenda[]) internal agendas;

    // Events
    event NewRelease(uint256 indexed release_id, address template, string api_version);
    event NewVault(address indexed token, uint256 indexed vault_id, address vault, string api_version);
    event NewExperimentalVault(address indexed token, address indexed deployer, address vault, string api_version);
    event NewGovernance(address governance);
    event VaultTagged(address vault, string tag);

    // Agenda events
    event AgendaCreated(address indexed vault, uint256 indexed agendaId, address indexed author, string title, uint8 riskLevel, string ipfsHash);
    event AgendaActivated(address indexed vault, uint256 indexed agendaId, bool active);
    event AgendaUpdatedMeta(address indexed vault, uint256 indexed agendaId, string[] metaTags);

    constructor() {
        governance = msg.sender;
    }

    // -------------------------
    // Governance
    // -------------------------
    function setGovernance(address _gov) external {
        require(msg.sender == governance, "unauthorized");
        pendingGovernance = _gov;
    }
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "unauthorized");
        governance = msg.sender;
        emit NewGovernance(msg.sender);
    }

    // -------------------------
    // Views
    // -------------------------
    function latestRelease() external view returns (string memory) {
        require(numReleases > 0, "no release");
        return IVaultRegistryView(releases[numReleases - 1]).apiVersion();
    }
    function latestVault(address token) external view returns (address) {
        require(numVaults[token] > 0, "no vault for token");
        return vaults[token][numVaults[token] - 1];
    }

    // -------------------------
    // Release management vault version
    // -------------------------
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

    // EIP-1167 minimal proxy clone using OpenZeppelin implementation
    function _clone(address implementation) internal returns (address instance) {
        return Clones.clone(implementation);
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

    function _registerVault(address token, address vault, address creator) internal {
        uint256 vault_id = numVaults[token]; // current count
        // ensure different api version than previous vault for the same token
        if (vault_id > 0) {
            string memory prev = IVaultRegistryView(vaults[token][vault_id - 1]).apiVersion();
            string memory next = IVaultRegistryView(vault).apiVersion();
            require(keccak256(bytes(prev)) != keccak256(bytes(next)), "same api version");
        }
        // register
        vaults[token][vault_id] = vault;
        numVaults[token] = vault_id + 1;
        if (!isRegistered[token]) {
            isRegistered[token] = true;
            tokens[numTokens] = token;
            numTokens += 1;
        }

        // remember creator for agenda authority
        vaultCreator[vault] = creator == address(0) ? msg.sender : creator;

        emit NewVault(token, vault_id, vault, IVaultRegistryView(vault).apiVersion());
    }

    // -------------------------
    // Vault creation
    // -------------------------
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
        _registerVault(token, vault, msg.sender);
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
        // store deployer as creator (msg.sender)
        _registerVault(token, vault, msg.sender);
        emit NewExperimentalVault(token, msg.sender, vault, IVaultRegistryView(vault).apiVersion());
        return vault;
    }

    // This function is to register existing vaults that match a release
    // Allow governance of a vault to register it directly, if it matches the target release
    function endorseVault(address vault, uint256 releaseDelta) external {
        require(msg.sender == governance, "unauthorized");
        require(IVaultRegistryView(vault).governance() == msg.sender, "not governed");
        uint256 releaseTarget = numReleases - 1 - releaseDelta; // underflow if none
        string memory api = IVaultRegistryView(releases[releaseTarget]).apiVersion();
        require(keccak256(bytes(IVaultRegistryView(vault).apiVersion())) == keccak256(bytes(api)), "not target release");
        _registerVault(IVaultRegistryView(vault).token(), vault, msg.sender);
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

    // -------------------------
    // Agenda API
    // -------------------------
    /**
     * @dev Access control helper: allowed to manage agendas if caller is:
     *  - registry governance
     *  - the vault's governance (IVaultRegistryView(vault).governance())
     *  - the vault creator (stored at registration)
     */
    function _isAgendaAdmin(address vault, address caller) internal view returns (bool) {
        if (caller == governance) return true;
        address vGov = address(0);
        // try to read governance from the vault; if the vault doesn't implement interface it will revert.
        // We expect vaults registered here to implement IVaultRegistryView.
        vGov = IVaultRegistryView(vault).governance();
        if (caller == vGov) return true;
        if (caller == vaultCreator[vault]) return true;
        return false;
    }

    /**
     * @notice Create a new agenda for a vault (appends new version)
     * @param vault the vault address
     * @param title short title (e.g., "Q4 yield acceleration")
     * @param content freeform content or JSON string (on-chain)
     * @param ipfsHash optional off-chain pointer (CID)
     * @param metaTags small array of meta tags
     * @param riskLevel 0..255 score (0 low, 255 high)
     */
    function createAgenda(
        address vault,
        string calldata title,
        string calldata content,
        string calldata ipfsHash,
        string[] calldata metaTags,
        uint8 riskLevel
    ) external returns (uint256) {
        require(_isAgendaAdmin(vault, msg.sender), "not authorized to create agenda");

        Agenda memory a;
        a.title = title;
        a.content = content;
        a.ipfsHash = ipfsHash;
        // copy tags
        uint256 len = metaTags.length;
        string[] memory tagsLocal = new string[](len);
        for (uint256 i = 0; i < len; i++) {
            tagsLocal[i] = metaTags[i];
        }
        a.metaTags = tagsLocal;
        a.riskLevel = riskLevel;
        a.timestamp = block.timestamp;
        a.author = msg.sender;
        a.active = true;

        agendas[vault].push(a);
        uint256 agendaId = agendas[vault].length - 1;

        emit AgendaCreated(vault, agendaId, msg.sender, title, riskLevel, ipfsHash);
        return agendaId;
    }

    /**
     * @notice Toggle active state of an agenda version (for deprecating/archiving)
     */
    function setAgendaActive(address vault, uint256 agendaId, bool active) external {
        require(_isAgendaAdmin(vault, msg.sender), "not authorized to toggle agenda");
        require(agendaId < agendas[vault].length, "agendaId OOB");
        agendas[vault][agendaId].active = active;
        emit AgendaActivated(vault, agendaId, active);
    }

    /**
     * @notice Update metaTags for an agenda version (allowed to provide additional labels)
     */
    function updateAgendaMetaTags(address vault, uint256 agendaId, string[] calldata metaTags) external {
        require(_isAgendaAdmin(vault, msg.sender), "not authorized to update meta");
        require(agendaId < agendas[vault].length, "agendaId OOB");
        // replace tags
        uint256 len = metaTags.length;
        string[] memory tagsLocal = new string[](len);
        for (uint256 i = 0; i < len; i++) {
            tagsLocal[i] = metaTags[i];
        }
        agendas[vault][agendaId].metaTags = tagsLocal;
        emit AgendaUpdatedMeta(vault, agendaId, metaTags);
    }

    // Read helpers

    /**
     * @notice Returns number of agendas for a vault
     */
    function agendaCount(address vault) external view returns (uint256) {
        return agendas[vault].length;
    }

    /**
     * @notice Get a single agenda entry
     */
    function getAgenda(address vault, uint256 agendaId)
        external
        view
        returns (
            string memory title,
            string memory content,
            string memory ipfsHash,
            string[] memory metaTags,
            uint8 riskLevel,
            uint256 timestamp,
            address author,
            bool active
        )
    {
        require(agendaId < agendas[vault].length, "agendaId OOB");
        Agenda storage a = agendas[vault][agendaId];
        return (a.title, a.content, a.ipfsHash, a.metaTags, a.riskLevel, a.timestamp, a.author, a.active);
    }

    /**
     * @notice Get latest agenda id for a vault, returns (exists, id)
     */
    function latestAgendaId(address vault) external view returns (bool exists, uint256 id) {
        uint256 len = agendas[vault].length;
        if (len == 0) return (false, 0);
        return (true, len - 1);
    }

    // -------------------------
    // Misc safety helpers (optional extensions)
    // -------------------------
    // Note: more Napfi-aligned features you might want next:
    //  - on-chain voting to approve agenda updates
    //  - minting agendas as NFTs (tokenize agenda ownership)
    //  - time-locked agenda activation windows
    //  - cross-vault agenda templates per release
}
