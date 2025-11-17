# Frontend Setup Complete ✅

## Overview
Full end-to-end Vite + React frontend for N6P smart contracts (Vault & Registry) on Base Sepolia.

## Quick Start
```bash
cd frontend
npm install
npm run dev
```
Open [http://localhost:5173](http://localhost:5173) in your browser.

## Architecture

### Contracts (on-chain, Base Sepolia)
- **Vault**: `0x11761e6bDef98e8fa7216dEe36068eD922B24Aaa` (ERC-4626)
- **Registry**: `0x2340F9643C18CEbfd7b6042AD8e23B205B286D78` (governance factory)

### Frontend Stack
- **Build**: Vite 5.0.0 + React 18.2.0
- **Web3**: ethers.js 5.7.2
- **Routing**: react-router-dom 6.20.0
- **State**: React Context (AddressContext) + localStorage

### Directory Structure
```
frontend/
  src/
    App.jsx                    # Router setup (BrowserRouter + Routes)
    main.jsx                   # Entry point
    components/
      Navigation.jsx           # Route links
      VaultWidget.jsx          # Vault deposit form + stats
      RegistryWidget.jsx       # Registry newVault form + stats
      AddressConfig.jsx        # Address input UI
      TxStatus.jsx             # Transaction status display
      EventViewer.jsx          # Decoded event display
      EventListener.jsx        # (hook, in hooks/)
    pages/
      EventsPage.jsx           # Aggregated contract events
      VaultDetailsPage.jsx     # Vault metadata grid
      RegistryManagementPage.jsx # Registry admin UI
      StrategiesPage.jsx       # Strategies dashboard
    hooks/
      useContract.js           # ethers Contract instantiation
      useTransaction.js        # Gas estimation + signing
      useEventListener.js      # Event subscription
    contexts/
      AddressContext.jsx       # Global address state
    abis/
      Vault.json               # Vault ABI (183 entries)
      Registry.json            # Registry ABI (27 entries)
    styles.css                 # Global styles
```

### Features Implemented

#### 1. **PHASE 1: Write Flows + Gas UX**
- ✅ `useTransaction` hook: Gas estimation, signing, status tracking
- ✅ `TxStatus` component: Visual feedback (⏳→🔐→📤→✅)
- ✅ Vault deposit form with gas display
- ✅ Registry newVault form with gas display
- ✅ MetaMask wallet connect
- ✅ Error handling + retry

#### 2. **PHASE 2: Event Listener**
- ✅ `useEventListener` hook: Fetch past events (-1000 blocks) + subscribe to new
- ✅ EventViewer component: Collapsible event display (block, tx hash, decoded args)
- ✅ EventsPage: Aggregates Vault (Deposit, Approval, StrategyAdded) & Registry (NewVault, NewRelease, NewGovernance) events
- ✅ Real-time event updates

#### 3. **PHASE 3: Routing + Pages**
- ✅ Navigation component with route links
- ✅ BrowserRouter + Routes configuration
- ✅ Dashboard (home): Vault + Registry widgets
- ✅ VaultDetailsPage: Vault metadata (name, symbol, decimals, governance, assets, etc.)
- ✅ RegistryManagementPage: Governance, releases, tagVault form
- ✅ StrategiesPage: Strategies dashboard (demo data ready for indexer)
- ✅ EventsPage: Contract event viewer

### How to Use

#### 1. **Connect Wallet**
```jsx
// VaultWidget and RegistryWidget have built-in "Connect MetaMask" button
// Automatically selects MetaMask signer for transactions
```

#### 2. **Update Contract Addresses**
```jsx
// Click "Edit Addresses" in AddressConfig component
// Addresses persist to localStorage (key: 'n6p_addresses_v1')
```

#### 3. **Make a Transaction (Deposit Example)**
```jsx
// Step 1: User enters amount in deposit form
// Step 2: Click "Deposit" → estimateGas() displays gas cost
// Step 3: Confirm in MetaMask
// Step 4: TxStatus shows: ⏳ estimating → 🔐 signing → 📤 submitted → ✅ confirmed
// Step 5: Vault stats (totalAssets, pricePerShare) automatically refresh
```

#### 4. **View Events**
```jsx
// Navigate to "Events" page
// Lists past events (-1000 block lookback) + subscribes to new
// Expandable event details (block#, tx hash, decoded args)
```

#### 5. **View Vault Details**
```jsx
// Navigate to "Vault Details"
// Grid display of metadata: name, symbol, decimals, governance, totalAssets, totalDebt, totalIdle, etc.
```

### Environment Variables
Create `frontend/.env.local`:
```env
VITE_RPC_URL=https://rpc.sepolia.basescan.org
VITE_VAULT_ADDRESS=0x11761e6bDef98e8fa7216dEe36068eD922B24Aaa
VITE_REGISTRY_ADDRESS=0x2340F9643C18CEbfd7b6042AD8e23B205B286D78
```
Or edit addresses directly in the UI (AddressConfig component).

### Key Hooks

#### `useContract(address, abi, { useSigner = false })`
Creates an ethers Contract instance.
- `useSigner=true`: Uses MetaMask signer (for write transactions)
- `useSigner=false`: Uses RPC provider (for read-only calls)

```jsx
const { contract } = useContract(address, abi, { useSigner: true })
await contract.deposit(amount)
```

#### `useTransaction()`
Manages transaction lifecycle.

```jsx
const { status, txHash, gasEstimate, sendTransaction, estimateGas, error } = useTransaction()

// Estimate gas
const gasEst = await estimateGas(() => contract.deposit(amount))

// Send transaction
await sendTransaction(() => contract.deposit(amount))
```

#### `useEventListener(contract, eventName, filters = {})`
Subscribes to contract events.

```jsx
const { events, loading, error } = useEventListener(contract, 'Deposit', {})
events.forEach(evt => console.log('Block:', evt.blockNumber, 'Args:', evt.args))
```

### Testing Checklist
- [ ] Connect MetaMask to Base Sepolia (chain ID 84532)
- [ ] Load frontend at http://localhost:5173
- [ ] Verify Navigation links work (Home, Vault Details, Registry Mgmt, Strategies, Events)
- [ ] Test Vault deposit form (gas estimate should update)
- [ ] Test Registry newVault form (gas estimate should update)
- [ ] Perform a transaction and confirm TxStatus feedback (⏳→✅)
- [ ] Check EventsPage for recent events
- [ ] Check VaultDetailsPage metadata displays correctly
- [ ] Change contract addresses in AddressConfig and verify reload persists

### Known Limitations
- **Strategies page**: Currently uses demo data; ready to wire to contract indexer
- **Event lookback**: -1000 blocks; add pagination UI for older events
- **Single account**: Currently assumes one MetaMask account; no multi-account support
- **Form validation**: Address format check (ethers.utils.isAddress) not yet implemented
- **Error boundaries**: Not yet wrapped around pages; error handling done at component level

### Next Steps (Optional Enhancements)
1. Add form validation (address, decimals, amounts)
2. Add error boundaries for page-level error handling
3. Add loading skeletons for async data
4. Wire Strategies page to actual contract/indexer
5. Add transaction history tracking (localStorage)
6. Add multi-chain support
7. Add ENS name resolution
8. Add localStorage backup/restore UI

### Support
Refer to:
- `frontend/README.md` — Full integration tutorial
- `FRONTEND_INTEGRATION.md` — Architecture & best practices
- Smart contract ABIs: `frontend/abis/Vault.json`, `frontend/abis/Registry.json`
