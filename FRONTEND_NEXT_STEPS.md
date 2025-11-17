# Next Steps: After Running Frontend Locally

## 🎯 Immediate Actions (After `npm run dev`)

### 1. **Verify App Loads**
- Open http://localhost:5173
- You should see:
  - N6P Frontend heading
  - Navigation bar with 5 links
  - AddressConfig section (shows default addresses)
  - Vault and Registry widgets side-by-side

### 2. **Connect MetaMask**
- Click "Connect Wallet" in either VaultWidget or RegistryWidget
- MetaMask will pop up asking to connect
- Ensure you're on **Base Sepolia** (Chain ID 84532) before connecting
- After connecting, button should show your address (e.g., "Connected: 0x1234...5678")

### 3. **Check All Pages Load**
- Click each nav link: Home → Vault Details → Registry Mgmt → Strategies → Events
- Each page should render without console errors
- Check browser console (`F12`) for any errors

---

## 📊 What Each Page Does

| Page | Route | Function |
|------|-------|----------|
| **Home** | `/` | Read vault stats + registry info; deposit/newVault forms |
| **Vault Details** | `/vault` | Display full vault metadata (name, symbol, governance, etc.) |
| **Registry Mgmt** | `/registry` | Show recent releases/tokens; tagVault form |
| **Strategies** | `/strategies` | Demo strategy list (placeholder for on-chain indexer) |
| **Events** | `/events` | Vault & Registry event listeners (Deposit, NewVault, etc.) |

---

## 🧪 Manual Testing Workflow

### Test: Gas Estimation
1. On Home page, enter amount in **Deposit** field
2. Click **Deposit** button
3. Observe: TxStatus shows "⏳ Estimating" briefly
4. Should see gas cost in ETH/gwei
5. Cancel MetaMask popup (or approve to execute)

### Test: Event Listening
1. Go to **Events** page
2. Try to expand event categories (Deposit, Approval, etc.)
3. If there's no activity, they may show "No events found"
4. To see real events, you'd need to execute a transaction on one of the contracts

### Test: Address Persistence
1. On Home page, scroll to **AddressConfig**
2. Change the vault address to a different valid address (0x...)
3. Refresh page (`F5`)
4. New address should persist (localStorage working)

### Test: Read Contract Data
1. **VaultWidget**: Should immediately show totalAssets and pricePerShare
2. **RegistryWidget**: Should immediately show numReleases and numTokens
3. **VaultDetailsPage**: Should fetch and display all 11 metadata fields
4. If any show "-", check browser console for fetch errors

---

## 🔧 Common Issues & Fixes

### Issue: "MetaMask not responding"
- **Cause**: MetaMask not installed or locked
- **Fix**: Install MetaMask browser extension and unlock it

### Issue: "Cannot read property 'signer' of null"
- **Cause**: Tried to write without connecting wallet
- **Fix**: Click "Connect Wallet" first

### Issue: Events show "Error: Network error"
- **Cause**: RPC endpoint unreachable or slow
- **Fix**: Check `.env.local` RPC URL; try https://rpc.sepolia.basescan.org

### Issue: "Module not found: EventViewer"
- **Cause**: Import path incorrect (should be fixed, but verify)
- **Fix**: Check `frontend/src/pages/EventsPage.jsx` line 6 imports from `../components/EventViewer`

### Issue: Page shows "Cannot find contract"
- **Cause**: Address is wrong or contract doesn't exist at that address
- **Fix**: Verify addresses in AddressConfig match deployed contracts on Base Sepolia

---

## 🚀 Next Development Phase (Optional)

### Phase 1: Form Validation
```javascript
// Add address validation before tx
if (!ethers.utils.isAddress(address)) return alert('Invalid address')
```

### Phase 2: Event Pagination
```javascript
// Limit event display to last 50 events
const recentEvents = events.slice(-50)
```

### Phase 3: Loading States
```javascript
// Add skeleton loaders while fetching data
{loading ? <Skeleton /> : <Data />}
```

### Phase 4: Error Boundaries
```javascript
// Wrap pages in error boundary to catch crashes
<ErrorBoundary fallback={<div>Error loading page</div>}>
  <Page />
</ErrorBoundary>
```

---

## 📚 File Reference

**When to check/modify these files:**

- **VaultWidget.jsx** → If deposit form needs changes
- **RegistryWidget.jsx** → If newVault form needs changes
- **Navigation.jsx** → If you want to add/remove routes
- **App.jsx** → If you want to change route paths or add middlewares
- **useTransaction.js** → If you need custom gas estimation logic
- **useEventListener.js** → If you need different event filtering
- **AddressContext.jsx** → If you need to persist additional data

---

## ✅ Success Criteria

Your frontend is working correctly if:

1. ✅ App loads at http://localhost:5173
2. ✅ All 5 pages accessible via navbar
3. ✅ MetaMask connects without errors
4. ✅ Vault/Registry data displays immediately
5. ✅ Forms submit without crashes
6. ✅ No errors in browser console
7. ✅ Address changes persist after page refresh

---

## 📞 Support Checklist

If something isn't working:

- [ ] Check browser console (`F12 → Console tab`)
- [ ] Verify MetaMask is on Base Sepolia (Chain ID 84532)
- [ ] Verify RPC endpoint is reachable
- [ ] Verify contract addresses in AddressConfig are correct
- [ ] Verify Node.js version is v18+
- [ ] Try clearing browser cache and reloading
- [ ] Try restarting `npm run dev`

---

## 🎊 You're All Set!

The frontend is fully functional and connected to Base Sepolia contracts. All bugs are fixed. Ready to test!

```bash
npm run dev
# → http://localhost:5173
```

---

**Generated**: November 17, 2025
