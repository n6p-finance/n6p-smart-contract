import React, { useEffect, useState } from 'react'
import { ethers } from 'ethers'
import RegistryAbi from '../../abis/Registry.json'
import useContract from '../hooks/useContract'
import useTransaction from '../hooks/useTransaction'
import TxStatus from './TxStatus'

export default function RegistryWidget({ address }){
  const { contract: readContract } = useContract(address, RegistryAbi, { useSigner: false })
  const { contract: writeContract } = useContract(address, RegistryAbi, { useSigner: true })
  const { status, error, txHash, gasEstimate, sendTransaction, estimateGas, reset } = useTransaction()

  const [numReleases, setNumReleases] = useState('-')
  const [numTokens, setNumTokens] = useState('-')
  const [latestRelease, setLatestRelease] = useState('')
  const [account, setAccount] = useState(null)
  const [newVaultForm, setNewVaultForm] = useState({
    token: '',
    guardian: '',
    rewards: '',
    name: '',
    symbol: '',
    releaseDelta: '0'
  })

  useEffect(()=>{
    if(!readContract) return
    readContract.numReleases().then(n=>setNumReleases(n.toString())).catch(()=>setNumReleases('-'))
    readContract.numTokens().then(n=>setNumTokens(n.toString())).catch(()=>setNumTokens('-'))
    readContract.latestRelease().then(v=>setLatestRelease(v)).catch(()=>setLatestRelease('-'))
  },[readContract])

  async function handleNewVault(){
    if(!writeContract) return alert('Connect wallet first')
    const { token, guardian, rewards, name, symbol, releaseDelta } = newVaultForm
    if(!token || !guardian || !rewards || !name || !symbol) return alert('Fill all fields')
    reset()
    try {
      await estimateGas({ to: address, data: writeContract.interface.encodeFunctionData('newVault', [token, guardian, rewards, name, symbol, releaseDelta]) })
      const receipt = await sendTransaction(
        () => writeContract.newVault(token, guardian, rewards, name, symbol, releaseDelta),
        []
      )
      if(receipt) {
        setNewVaultForm({ token: '', guardian: '', rewards: '', name: '', symbol: '', releaseDelta: '0' })
        const nr = await readContract.numReleases()
        setNumReleases(nr.toString())
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
      <h3>Registry</h3>
      <div><strong>Address:</strong> {address}</div>
      <div><strong>Num releases:</strong> {numReleases}</div>
      <div><strong>Num tokens:</strong> {numTokens}</div>
      <div><strong>Latest release:</strong> {latestRelease || '-'}</div>
      
      <div style={{marginTop:12}}>
        <button onClick={connectWallet}>{account ? `Connected: ${account.slice(0,6)}...${account.slice(-4)}` : 'Connect Wallet'}</button>
      </div>

      <div style={{marginTop:12, padding:8, backgroundColor:'#f9f9f9', borderRadius:4}}>
        <h4>Create New Vault</h4>
        {['token', 'guardian', 'rewards'].map(field => (
          <div key={field} style={{marginBottom:6}}>
            <label>{field} (address)</label>
            <input 
              value={newVaultForm[field]} 
              onChange={e=>setNewVaultForm({...newVaultForm, [field]: e.target.value})}
              placeholder={`0x...`}
              style={{width:'100%'}}
            />
          </div>
        ))}
        {['name', 'symbol'].map(field => (
          <div key={field} style={{marginBottom:6}}>
            <label>{field}</label>
            <input 
              value={newVaultForm[field]} 
              onChange={e=>setNewVaultForm({...newVaultForm, [field]: e.target.value})}
              placeholder={field}
              style={{width:'100%'}}
            />
          </div>
        ))}
        <div style={{marginBottom:6}}>
          <label>releaseDelta</label>
          <input 
            type="number"
            value={newVaultForm.releaseDelta} 
            onChange={e=>setNewVaultForm({...newVaultForm, releaseDelta: e.target.value})}
            style={{width:'100%'}}
          />
        </div>
        <button onClick={handleNewVault}>Create Vault</button>
      </div>

      <TxStatus status={status} error={error} txHash={txHash} gasEstimate={gasEstimate} />
    </div>
  )
}
