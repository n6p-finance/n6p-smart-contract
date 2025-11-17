import React, { useContext, useEffect, useState } from 'react'
import { AddressContext } from '../contexts/AddressContext'
import VaultAbi from '../../abis/Vault.json'
import useContract from '../hooks/useContract'

export default function StrategiesPage(){
  const { addresses } = useContext(AddressContext)
  const { contract } = useContract(addresses.vault, VaultAbi, { useSigner: false })
  
  const [strategies, setStrategies] = useState([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if(!contract) return
    // Note: Vault ABI may not expose all strategies; this is a placeholder
    // In production, you'd fetch from events or off-chain indexer
    setLoading(true)
    setTimeout(() => {
      setStrategies([
        { address: '0x...', debtRatio: '5000', name: 'Strategy 1' },
        { address: '0x...', debtRatio: '3000', name: 'Strategy 2' }
      ])
      setLoading(false)
    }, 500)
  }, [contract])

  return (
    <div style={{marginTop:16}}>
      <h2>Strategies</h2>
      {loading && <div>Loading strategies...</div>}
      {!loading && strategies.length === 0 && <div>No strategies found. (This is demo data)</div>}
      {strategies.map((strat, idx) => (
        <div key={idx} style={{marginTop:8, padding:12, border:'1px solid #ddd', borderRadius:4}}>
          <h4>{strat.name}</h4>
          <div><strong>Address:</strong> <code style={{fontSize:11}}>{strat.address}</code></div>
          <div><strong>Debt Ratio:</strong> {strat.debtRatio}</div>
        </div>
      ))}
    </div>
  )
}
