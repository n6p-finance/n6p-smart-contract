# 🚀 COMPLETE LOCAL SETUP GUIDE

## Prerequisites Check

Before running, verify you have:

- **Node.js v18+** installed → Check: `node --version`
- **npm v9+** installed → Check: `npm --version`
- **MetaMask browser extension** installed
- **Base Sepolia configured** in MetaMask (Chain ID: 84532)

If you don't have these, stop here and install them first:
- **Node.js & npm**: https://nodejs.org/ (Download v18 LTS)
- **MetaMask**: https://metamask.io/

---

## Step 1: Copy Project to Your Machine

**Windows**:
```cmd
# Download the project folder, or use:
git clone <your-repo-url>
cd n6p-smart-contract
```

**Mac/Linux**:
```bash
# Same as above
git clone <your-repo-url>
cd n6p-smart-contract
```

---

## Step 2: Verify Directory Structure

Run this command to verify the frontend folder exists:

```bash
ls -la frontend/
```

You should see:
```
package.json
vite.config.js
index.html
.env.local
src/
abis/
```

---

## Step 3: Install Dependencies

Navigate to the frontend folder and install:

```bash
cd frontend
npm install
```

**What this does**: Downloads React, ethers.js, Vite, and other dependencies (~500MB)

**Expected output**:
```
added XXX packages in XXs
```

⏱️ **This takes 1-3 minutes** depending on your internet speed.

---

## Step 4: Start the Development Server

Run:

```bash
npm run dev
```

**Expected output**:
```
  VITE v5.0.0  ready in 543 ms

  ➜  Local:   http://localhost:5173/
  ➜  press h to show help
```

**Important**: Do NOT close this terminal. The dev server must stay running.

---

## Step 5: Open in Browser

1. **Open your browser** (Chrome, Firefox, Edge, or Brave)
2. **Go to**: http://localhost:5173/
3. **You should see**:
   - N6P Frontend heading
   - Navigation bar with 5 menu items
   - AddressConfig section
   - Vault and Registry widgets

---

## Step 6: Connect MetaMask

1. **Look for a small notification** asking to connect MetaMask
   - Or click **"Connect Wallet"** button in the Vault or Registry widget
2. **MetaMask popup will appear** asking for permission
3. **Make sure MetaMask is on Base Sepolia**:
   - Look at top of MetaMask popup
   - Should show: "Base Sepolia" with Chain ID 84532
   - If not, click network dropdown and select Base Sepolia

4. **Click "Connect"** in MetaMask

After connecting, you should see:
- Button shows your wallet address (e.g., "Connected: 0x1234...5678")
- No red error messages

---

## Step 7: Test the App

### Test 1: View Vault Data
- Home page should immediately show:
  - Total Assets: `[number]`
  - Price Per Share: `[number]`

### Test 2: View Registry Data
- Home page should show:
  - Num releases: `[number]`
  - Num tokens: `[number]`

### Test 3: Navigate All Pages
Click each menu item:
- ✅ Home → Should show Vault + Registry
- ✅ Vault Details → Should show 11 metadata fields
- ✅ Registry Mgmt → Should show recent releases/tokens
- ✅ Strategies → Should show demo strategies
- ✅ Events → Should show 6 event categories

### Test 4: Check Console
Press `F12` to open developer tools → Console tab

You should see **NO red error messages**.

If you see red errors, note them and check the troubleshooting section below.

---

## Step 8: Test Write Flow (Optional)

If you have testnet ETH on Base Sepolia:

1. **Go to Home page**
2. **Find the Deposit form** (Vault widget)
3. **Enter an amount** (e.g., `1000000` for small deposit)
4. **Click "Deposit"**
5. **Observe**:
   - Button shows "⏳ Estimating..." 
   - Gas cost appears (e.g., "0.001 ETH")
   - MetaMask popup appears
   - Choose "Approve" or "Reject"

---

## 🎉 Success Indicators

Your frontend is working correctly if you see:

- [x] App loads at http://localhost:5173
- [x] Navigation bar visible with 5 menu items
- [x] Vault/Registry data displays
- [x] MetaMask connects without errors
- [x] All 5 pages load without crashing
- [x] Console has NO red errors
- [x] Forms are clickable (no crashes)

---

## ❌ Troubleshooting

### Issue: "Port 5173 already in use"

**Solution**: Stop other Vite servers, or use a different port:
```bash
npm run dev -- --port 5174
```

### Issue: "Cannot find module 'ethers'"

**Solution**: Dependencies not installed. Run:
```bash
npm install
```

### Issue: MetaMask says "Cannot read property 'signer' of null"

**Solution**: You tried to write without connecting wallet. Click "Connect Wallet" first.

### Issue: "Contract data shows '-' for all values"

**Solutions**:
1. Verify contract addresses in AddressConfig are correct
2. Check if addresses exist on Base Sepolia
3. Check browser console (F12) for network errors
4. Try different RPC endpoint in `.env.local`

### Issue: "Page shows blank/white screen"

**Solutions**:
1. Press `Ctrl+Shift+R` to hard refresh browser
2. Check console (F12) for errors
3. Restart the dev server (`npm run dev`)
4. Clear browser cache

### Issue: MetaMask not appearing on page

**Solutions**:
1. Make sure MetaMask extension is installed
2. Make sure MetaMask is unlocked (enter password if needed)
3. Try refreshing page (F5)
4. Check MetaMask is set to Base Sepolia

### Issue: Events page shows "No events found" or "Error"

**This is normal** if no transactions have occurred. Events will appear after you execute a transaction.

---

## 🔧 Useful Commands

| Command | What it does |
|---------|-------------|
| `npm run dev` | Start dev server (port 5173) |
| `npm run build` | Build for production |
| `npm run preview` | Preview production build |
| `npm install` | Install/update dependencies |
| `npm install ethers@latest` | Update ethers.js |

---

## 📱 Accessing from Other Devices

**From another computer on same network**:

1. Find your computer's IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
2. Go to: `http://<YOUR_IP>:5173` on other device

**Example**:
```
Your IP: 192.168.1.100
Other device: http://192.168.1.100:5173
```

---

## 🛑 Stopping the Server

Press `Ctrl+C` in the terminal where `npm run dev` is running.

---

## 🎓 Next Steps After Success

1. **Interact with contracts**: Use forms to execute transactions
2. **Monitor events**: Go to Events page and perform transactions to see them
3. **Edit addresses**: Use AddressConfig to switch between contracts
4. **Build for production**: Run `npm run build` to create optimized build

---

## 📞 Getting Help

If something goes wrong:

1. **Check console** (`F12 → Console`)
2. **Note the error message** (screenshot it)
3. **Check FRONTEND_TESTING.md** for common bugs
4. **Check FRONTEND_NEXT_STEPS.md** for detailed troubleshooting
5. **Verify Node.js version**: `node --version` (should be v18+)

---

## ✅ You're Ready!

**Summary of what to do**:

```bash
# 1. Navigate to frontend
cd frontend

# 2. Install dependencies (one time)
npm install

# 3. Start dev server
npm run dev

# 4. Open http://localhost:5173 in browser
# 5. Connect MetaMask to Base Sepolia
# 6. Explore all 5 pages!
```

**That's it!** The app is now running and connected to Base Sepolia contracts. 🎉

---

**Any issues?** Check browser console (`F12`) for error details.
