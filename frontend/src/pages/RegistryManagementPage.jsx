import React, { useContext, useEffect, useState } from 'react'
import { AddressContext } from '../contexts/AddressContext'
import RegistryAbi from '../../abis/Registry.json'
import useContract from '../hooks/useContract'
import useTransaction from '../hooks/useTransaction'
import TxStatus from '../components/TxStatus'

export default function RegistryManagementPage(){
  const { addresses } = useContext(AddressContext)
  const { contract: readContract } = useContract(addresses.registry, RegistryAbi, { useSigner: false })
  const { contract: writeContract } = useContract(addresses.registry, RegistryAbi, { useSigner: true })
  const { status, error, txHash, gasEstimate, sendTransaction, reset } = useTransaction()

  const [releases, setReleases] = useState([])
  const [tokens, setTokens] = useState([])
  const [governance, setGovernance] = useState('-')
  const [tagVaultForm, setTagVaultForm] = useState({ vault: '', tag: '' })

  useEffect(() => {
    if(!readContract) return

    readContract.numReleases().then(n => {
      const promises = []
      for(let i = 0; i < Math.min(n, 5); i++) {
        promises.push(readContract.releases(i))
      }
      return Promise.all(promises)
    }).then(rels => setReleases(rels))

    readContract.numTokens().then(n => {
      const promises = []
      for(let i = 0; i < Math.min(n, 5); i++) {
        promises.push(readContract.tokens(i))
      }
      return Promise.all(promises)
    }).then(toks => setTokens(toks))

    readContract.governance().then(g => setGovernance(g))
  }, [readContract])

  async function handleTagVault(){
    if(!writeContract) return alert('Connect wallet')
    const { vault, tag } = tagVaultForm
    if(!vault || !tag) return alert('Fill all fields')
    reset()
    try {
      const receipt = await sendTransaction(() => writeContract.tagVault(vault, tag), [])
      if(receipt) {
        setTagVaultForm({ vault: '', tag: '' })
      }
    } catch (e) {
      console.error(e)
    }
  }

  return (
    <div style={{marginTop:16}}>
      <h2>Registry Management</h2>

      <div style={{marginTop:12}}>
        <h3>Registry Info</h3>
        <div><strong>Governance:</strong> {governance}</div>
      </div>

      <div style={{marginTop:12}}>
        <h3>Recent Releases ({releases.length})</h3>
        {releases.map((addr, idx) => (
          <div key={idx} style={{padding:6, backgroundColor:'#f0f0f0', marginBottom:4, borderRadius:3, fontSize:12, fontFamily:'monospace'}}>
            {addr}
          </div>
        ))}
      </div>

      <div style={{marginTop:12}}>
        <h3>Recent Tokens ({tokens.length})</h3>
        {tokens.map((addr, idx) => (
          <div key={idx} style={{padding:6, backgroundColor:'#f0f0f0', marginBottom:4, borderRadius:3, fontSize:12, fontFamily:'monospace'}}>
            {addr}
          </div>
        ))}
      </div>

      <div style={{marginTop:12, padding:8, backgroundColor:'#f9f9f9', borderRadius:4}}>
        <h4>Tag Vault</h4>
        <div style={{marginBottom:6}}>
          <label>Vault Address</label>
          <input 
            value={tagVaultForm.vault} 
            onChange={e=>setTagVaultForm({...tagVaultForm, vault: e.target.value})}
            placeholder="0x..."
            style={{width:'100%'}}
          />
        </div>
        <div style={{marginBottom:6}}>
          <label>Tag</label>
          <input 
            value={tagVaultForm.tag} 
            onChange={e=>setTagVaultForm({...tagVaultForm, tag: e.target.value})}
            placeholder="e.g. Experimental"
            style={{width:'100%'}}
          />
        </div>
        <button onClick={handleTagVault}>Tag Vault</button>
      </div>

      <TxStatus status={status} error={error} txHash={txHash} gasEstimate={gasEstimate} />
    </div>
  )
}
