# ⚡ QUICK START CARD

## 🎯 TL;DR - Just Run This

```bash
cd frontend
npm install
npm run dev
```

Then open: **http://localhost:5173**

---

## ✅ Before You Start

- [ ] Node.js v18+ installed? → `node --version`
- [ ] npm installed? → `npm --version`
- [ ] MetaMask installed (browser extension)?
- [ ] MetaMask switched to **Base Sepolia** (Chain 84532)?

**Missing something?**
- Node.js: https://nodejs.org/
- MetaMask: https://metamask.io/

---

## 🚀 The 3-Step Process

### Step 1: Install
```bash
cd frontend
npm install
```
⏱️ Takes 1-3 minutes

### Step 2: Start
```bash
npm run dev
```

### Step 3: Open Browser
Go to: **http://localhost:5173**

---

## 🔌 What You'll See

| Item | Status |
|------|--------|
| App loads? | ✅ Should see N6P heading |
| Menu bar? | ✅ 5 links (Home, Vault, Registry, Strategies, Events) |
| Connect button? | ✅ Click to connect MetaMask |
| Data displays? | ✅ Should show Vault/Registry info immediately |

---

## 🎮 How to Test

1. **See Vault data** → Home page shows totalAssets & pricePerShare
2. **See Registry data** → Shows numReleases & numTokens
3. **View all pages** → Click each nav link
4. **Connect MetaMask** → Click "Connect Wallet" button
5. **Try a form** → Click "Deposit" button (gas estimate will show)
6. **Check console** → Press `F12`, should have NO red errors

---

## ❌ Quick Fixes

| Problem | Fix |
|---------|-----|
| Node not found | Install Node.js v18+ |
| "Port already in use" | `npm run dev -- --port 5174` |
| MetaMask not connecting | Unlock MetaMask, switch to Base Sepolia |
| Page shows "-" for data | Check addresses in AddressConfig |
| Console shows red errors | Take screenshot, check FRONTEND_TESTING.md |
| "Module not found: ethers" | Run `npm install` again |

---

## 🔗 Network Config (Pre-configured)

| Item | Value |
|------|-------|
| Chain | Base Sepolia |
| Chain ID | 84532 |
| RPC | https://rpc.sepolia.basescan.org |
| Vault | 0x11761e6b...24Aaa |
| Registry | 0x2340F964...6D78 |

**Already configured in `.env.local` - no changes needed!**

---

## 📊 What's Running

✅ React app (Vite dev server)  
✅ 5 pages with navigation  
✅ 2 smart contracts connected  
✅ MetaMask wallet integration  
✅ Real-time event listeners  
✅ Gas estimation UI  
✅ Transaction feedback

---

## 🎯 Success = All These Working

```
✅ App loads
✅ No console errors
✅ MetaMask connects
✅ Contract data displays
✅ All 5 pages load
✅ Forms are clickable
✅ Navigation works
```

---

## 📞 Still Stuck?

1. Check: **LOCAL_SETUP_GUIDE.md** (detailed step-by-step)
2. Check: **FRONTEND_TESTING.md** (bug troubleshooting)
3. Check: **FRONTEND_NEXT_STEPS.md** (testing workflow)
4. Check: Browser console (`F12`) for error messages

---

## 🎉 That's It!

Run these commands and you're done:

```bash
cd frontend && npm install && npm run dev
```

Open: http://localhost:5173

Connect MetaMask to Base Sepolia.

Explore the 5 pages! 🚀

---

**Generated**: November 17, 2025
