import { useEffect, useState } from 'react'
import { ethers } from 'ethers'

export default function useContract(address, abi, { useSigner=false } = {}){
  const [contract, setContract] = useState(null)
  const [provider, setProvider] = useState(null)

  useEffect(()=>{
    if(!address || !abi) return setContract(null)
    // prefer injected provider for signer
    if(useSigner && typeof window !== 'undefined' && window.ethereum){
      const p = new ethers.providers.Web3Provider(window.ethereum)
      const signer = p.getSigner()
      try{ setContract(new ethers.Contract(address, abi, signer)); setProvider(p); }
      catch(e){ setContract(null) }
      return
    }

    // fallback to JSON-RPC provider (VITE_RPC_URL injected by Vite)
    const rpc = import.meta.env.VITE_RPC_URL || 'https://rpc.sepolia.basescan.org'
    const p = new ethers.providers.JsonRpcProvider(rpc)
    try{ setContract(new ethers.Contract(address, abi, p)); setProvider(p); }
    catch(e){ setContract(null) }
  }, [address, abi, useSigner])

  return { contract, provider }
}
