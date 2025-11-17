import React from 'react'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import VaultWidget from './components/VaultWidget'
import VaultAbi from '../abis/Vault.json'
import AddressConfig from './components/AddressConfig'
import RegistryWidget from './components/RegistryWidget'
import Navigation from './components/Navigation'
import { AddressProvider, AddressContext } from './contexts/AddressContext'
import EventsPage from './pages/EventsPage'
import VaultDetailsPage from './pages/VaultDetailsPage'
import RegistryManagementPage from './pages/RegistryManagementPage'
import StrategiesPage from './pages/StrategiesPage'

export default function App(){
  return (
    <AddressProvider>
      <BrowserRouter>
        <Main />
      </BrowserRouter>
    </AddressProvider>
  )
}

function Main(){
  const { addresses } = React.useContext(AddressContext)
  return (
    <div className="app">
      <h1>N6P Frontend (Vite + React)</h1>
      <p>Using ABIs in <code>frontend/abis/</code></p>
      <Navigation />
      <AddressConfig />
      <Routes>
        <Route path="/" element={
          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:20}}>
            <div>
              <h2>Vault</h2>
              <VaultWidget address={addresses.vault} abi={VaultAbi} />
            </div>
            <div>
              <RegistryWidget address={addresses.registry} />
            </div>
          </div>
        } />
        <Route path="/vault" element={<VaultDetailsPage address={addresses.vault} />} />
        <Route path="/registry" element={<RegistryManagementPage address={addresses.registry} />} />
        <Route path="/strategies" element={<StrategiesPage />} />
        <Route path="/events" element={<EventsPage />} />
      </Routes>
    </div>
  )
}
