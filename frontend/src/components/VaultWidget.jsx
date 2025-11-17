import React, { useEffect, useState } from 'react'
import { ethers } from 'ethers'
import VaultAbi from '../../abis/Vault.json'
import useContract from '../hooks/useContract'
import useTransaction from '../hooks/useTransaction'
import TxStatus from './TxStatus'

export default function VaultWidget({ address }){
  const { contract: readContract } = useContract(address, VaultAbi, { useSigner: false })
  const { contract: writeContract } = useContract(address, VaultAbi, { useSigner: true })
  const { status, error, txHash, gasEstimate, sendTransaction, estimateGas, reset } = useTransaction()

  const [totalAssets, setTotalAssets] = useState('-')
  const [pricePerShare, setPricePerShare] = useState('-')
  const [depositAmount, setDepositAmount] = useState('')
  const [account, setAccount] = useState(null)

  useEffect(()=>{
    if(!readContract) return
    readContract.totalAssets().then(t=>setTotalAssets(t.toString())).catch(()=>setTotalAssets('-'))
    readContract.pricePerShare().then(p=>setPricePerShare(ethers.utils.formatEther(p))).catch(()=>setPricePerShare('-'))
  },[readContract])

  async function handleDeposit(){
    if(!writeContract || !depositAmount) return
    reset()
    try {
      const addr = await writeContract.signer.getAddress()
      await estimateGas({ to: address, data: writeContract.interface.encodeFunctionData('deposit', [depositAmount, addr]) })
      const receipt = await sendTransaction(
        () => writeContract.deposit(depositAmount, addr),
        []
      )
      if(receipt) {
        setDepositAmount('')
        const ta = await readContract.totalAssets()
        setTotalAssets(ta.toString())
      }
    } catch (e) {
      console.error(e)
    }
  }

  async function connectWallet(){
    if(!window.ethereum) return alert('Install MetaMask')
    try {
      await window.ethereum.request({ method: 'eth_requestAccounts' })
      const provider = new ethers.providers.Web3Provider(window.ethereum)
      const signer = provider.getSigner()
      setAccount(await signer.getAddress())
    } catch (e) {
      console.error(e)
    }
  }

  return (
    <div style={{marginTop:12, padding:12, border:'1px solid #ddd', borderRadius:6}}>
      <h3>Vault</h3>
      <div><strong>Address:</strong> {address}</div>
      <div><strong>Total Assets:</strong> {totalAssets}</div>
      <div><strong>Price Per Share:</strong> {pricePerShare}</div>
      
      <div style={{marginTop:12}}>
        <button onClick={connectWallet}>{account ? `Connected: ${account.slice(0,6)}...${account.slice(-4)}` : 'Connect Wallet'}</button>
      </div>

      <div style={{marginTop:12}}>
        <label>Deposit Amount</label>
        <input 
          placeholder="Amount in smallest units" 
          value={depositAmount} 
          onChange={e=>setDepositAmount(e.target.value)} 
          style={{width:'100%'}}
        />
        <button onClick={handleDeposit} style={{marginTop:6}}>Deposit</button>
      </div>

      <TxStatus status={status} error={error} txHash={txHash} gasEstimate={gasEstimate} />
    </div>
  )
}
