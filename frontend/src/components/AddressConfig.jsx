import React from 'react'
import { AddressContext } from '../contexts/AddressContext'

export default function AddressConfig(){
  const { addresses, setAddresses } = React.useContext(AddressContext)
  const [vault, setVault] = React.useState(addresses.vault)
  const [registry, setRegistry] = React.useState(addresses.registry)

  function save(e){
    e.preventDefault()
    setAddresses({ vault, registry })
  }

  function reset(){
    setVault(addresses.vault)
    setRegistry(addresses.registry)
  }

  return (
    <form onSubmit={save} style={{marginBottom:12}}>
      <div style={{marginBottom:6}}>
        <label>Vault address</label>
        <input value={vault} onChange={e=>setVault(e.target.value)} style={{width:'100%'}} />
      </div>
      <div style={{marginBottom:6}}>
        <label>Registry address</label>
        <input value={registry} onChange={e=>setRegistry(e.target.value)} style={{width:'100%'}} />
      </div>
      <div>
        <button type="submit">Save</button>
        <button type="button" onClick={reset} style={{marginLeft:8}}>Revert</button>
      </div>
    </form>
  )
}
