# Frontend Integration Guide (ABIs)

This document shows how to integrate the exported ABIs in `frontend/abis` into a simple frontend app. It covers
quick local testing with the example pages, a minimal React setup, and notes about provider selection and common pitfalls.

Paths in this repo
- Vault ABI: `frontend/abis/Vault.json` (raw ABI array)
- Registry ABI: `frontend/abis/Registry.json` (raw ABI array)
- Example pages: `frontend/examples/abi-demo.html` and `frontend/examples/react-lite.html`

Prerequisites
- Node.js (for npm examples) — optional for the static demos
- A browser with MetaMask (or another injected wallet) for signing transactions
- A local static file server to run the example demos (or a web server such as nginx)

Serving the examples locally (quick)
1. From the repository root run a simple static server (Python built-in):

```bash
# run from project root
python3 -m http.server 8000
```

2. Open the demo pages in your browser:

- HTML demo: http://localhost:8000/frontend/examples/abi-demo.html
- React-lite demo: http://localhost:8000/frontend/examples/react-lite.html

These pages load the ABI from `../abis/Vault.json` and attempt to connect with MetaMask. They are intentionally minimal so you can inspect how the ABI is consumed.

Using the ABI in a web app (ethers.js)

Example: instantiate a contract using ethers.js (ES module / Node-style)

```js
import { ethers } from 'ethers';
import VaultAbi from './abis/Vault.json'; // if your bundler supports JSON imports

const VAULT_ADDRESS = '0x11761e6bDef98e8fa7216dEe36068eD922B24Aaa';

// Read-only with a public RPC provider
const provider = new ethers.providers.JsonRpcProvider(process.env.REACT_APP_RPC_URL /* e.g. https://rpc.sepolia.basescan.org */);
const vaultRead = new ethers.Contract(VAULT_ADDRESS, VaultAbi, provider);
const totalAssets = await vaultRead.totalAssets();

// For signed transactions, use a signer from the provider (MetaMask)
const web3Provider = new ethers.providers.Web3Provider(window.ethereum);
await web3Provider.send('eth_requestAccounts', []);
const signer = web3Provider.getSigner();
const vaultWrite = new ethers.Contract(VAULT_ADDRESS, VaultAbi, signer);
const tx = await vaultWrite.deposit('1000000000000000000', await signer.getAddress());
await tx.wait();
```

Notes about ABI file format
- `Registry.json` and `Vault.json` are both saved as plain JSON arrays (not wrapped in an `abi` key). Some tools (Truffle, hardhat) produce objects with an `abi` field — if you import an object, extract the `.abi` array. The example pages (`abi-demo.html` and `react-lite.html`) handle either shape.
- Keep the ABI and the deployed address in sync. The ABI alone doesn't tell you the address; use the addresses from your deployment or the `run-latest.json` broadcast file.

React / Vite / CRA usage notes
- In a React app (Create React App or Vite) you can `import VaultAbi from '../frontend/abis/Vault.json'` and use it with ethers as shown above. Vite and CRA support JSON imports by default.
- Use environment variables for RPC endpoints and default addresses (e.g., `VITE_RPC_URL` or `REACT_APP_RPC_URL`).

Security and UX recommendations
- Never hardcode private keys in the frontend. For read-only calls you can use a public RPC provider; for writes require users to sign via MetaMask or WalletConnect. 
- Show clear gas/confirmation UX when sending transactions. The demo pages are intentionally simple — add error handling and UX improvements for production.

Dealing with upgradeable contracts and proxies
- The Vault implementation includes upgrade-related functions in its ABI (`upgradeTo`, `proxiableUUID`, etc.). If the deployed address is a proxy, interacting with the proxy address using the implementation ABI works for calling application methods.
- If you need to call admin/upgrade methods, confirm you are addressing the implementation or proxy depending on your deployment architecture and EIP-1967 storage slots.

Verifications & Explorer
- Explorer verification is useful for public transparency. The local ABIs let your app call the contracts regardless of whether the source is verified on the explorer. If verification fails, you may need to reproduce exact compiler settings and metadata to satisfy the verifier.

Debugging tips
- If `contract.functionName` is not a function, double-check that you used the correct ABI for the given address.
- Use `provider.getCode(address)` to confirm that the on-chain bytecode is non-empty and `contract.provider.getBalance(address)` to check funding on accounts.

Example: Minimal React component (snippet)

```jsx
import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import VaultAbi from '../abis/Vault.json';

export default function VaultWidget({ address }){
  const [total, setTotal] = useState('-');

  useEffect(()=>{
    const provider = new ethers.providers.JsonRpcProvider(process.env.REACT_APP_RPC_URL);
    const c = new ethers.Contract(address, VaultAbi, provider);
    c.totalAssets().then(t => setTotal(t.toString())).catch(e=>setTotal('err'));
  },[address]);

  return (<div>Vault {address} — TotalAssets: {total}</div>);
}
```

Where to go next
- If you want I can:
  - Add a small `package.json` and a minimal React + Vite starter inside `frontend/` wired to these ABIs.
  - Add provider fallback logic to the example pages (so they work read-only without MetaMask).
  - Poll the verification GUIDs and append the verification status to the README.

Feel free to tell me which of those you'd like me to implement next.
