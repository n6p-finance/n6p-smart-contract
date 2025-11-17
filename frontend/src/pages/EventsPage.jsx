import React, { useContext } from 'react'
import { AddressContext } from '../contexts/AddressContext'
import VaultAbi from '../../abis/Vault.json'
import RegistryAbi from '../../abis/Registry.json'
import useContract from '../hooks/useContract'
import EventViewer from '../components/EventViewer'

export default function EventsPage(){
  const { addresses } = useContext(AddressContext)
  const { contract: vaultContract } = useContract(addresses.vault, VaultAbi, { useSigner: false })
  const { contract: registryContract } = useContract(addresses.registry, RegistryAbi, { useSigner: false })

  return (
    <div style={{marginTop:12}}>
      <h2>Smart Contract Events</h2>
      
      <div style={{marginTop:16}}>
        <h3>Vault Events</h3>
        <EventViewer contract={vaultContract} eventName="Deposit" description="User deposits" />
        <EventViewer contract={vaultContract} eventName="Approval" description="Token approvals" />
        <EventViewer contract={vaultContract} eventName="StrategyAdded" description="New strategy added" />
      </div>

      <div style={{marginTop:16}}>
        <h3>Registry Events</h3>
        <EventViewer contract={registryContract} eventName="NewVault" description="Vault created" />
        <EventViewer contract={registryContract} eventName="NewRelease" description="Release added" />
        <EventViewer contract={registryContract} eventName="NewGovernance" description="Governance changed" />
      </div>
    </div>
  )
}
