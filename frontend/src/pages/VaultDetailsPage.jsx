import React, { useContext, useEffect, useState } from 'react'
import { AddressContext } from '../contexts/AddressContext'
import VaultAbi from '../../abis/Vault.json'
import useContract from '../hooks/useContract'

export default function VaultDetailsPage(){
  const { addresses } = useContext(AddressContext)
  const { contract } = useContract(addresses.vault, VaultAbi, { useSigner: false })
  
  const [details, setDetails] = useState({
    name: '-',
    symbol: '-',
    decimals: '-',
    token: '-',
    governance: '-',
    guardian: '-',
    management: '-',
    totalSupply: '-',
    totalAssets: '-',
    totalDebt: '-',
    totalIdle: '-'
  })

  useEffect(() => {
    if(!contract) return
    
    Promise.all([
      contract.name(),
      contract.symbol(),
      contract.decimals(),
      contract.token(),
      contract.governance(),
      contract.guardian(),
      contract.management(),
      contract.totalSupply(),
      contract.totalAssets(),
      contract.totalDebt(),
      contract.totalIdle()
    ]).then(([name, symbol, decimals, token, gov, guardian, mgmt, supply, assets, debt, idle]) => {
      setDetails({
        name, symbol, decimals: decimals.toString(), token, governance: gov, guardian, management: mgmt,
        totalSupply: supply.toString(), totalAssets: assets.toString(), totalDebt: debt.toString(), totalIdle: idle.toString()
      })
    }).catch(e => console.error(e))
  }, [contract])

  return (
    <div style={{marginTop:16}}>
      <h2>Vault Details</h2>
      <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:12}}>
        {Object.entries(details).map(([key, val]) => (
          <div key={key} style={{padding:8, backgroundColor:'#f9f9f9', borderRadius:4}}>
            <strong>{key}:</strong>
            <div style={{fontSize:12, wordBreak:'break-all', marginTop:4, fontFamily:'monospace'}}>{val}</div>
          </div>
        ))}
      </div>
    </div>
  )
}
