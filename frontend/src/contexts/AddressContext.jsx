import React from 'react'

const STORAGE_KEY = 'n6p_addresses_v1'

const defaultAddresses = {
  vault: '0x11761e6bDef98e8fa7216dEe36068eD922B24Aaa',
  registry: '0x2340F9643C18CEbfd7b6042AD8e23B205B286D78'
}

export const AddressContext = React.createContext({
  addresses: defaultAddresses,
  setAddresses: () => {}
})

export function AddressProvider({ children }){
  const [addresses, setAddressesState] = React.useState(()=>{
    try{
      const raw = localStorage.getItem(STORAGE_KEY)
      return raw ? JSON.parse(raw) : defaultAddresses
    }catch(e){ return defaultAddresses }
  })

  function setAddresses(next){
    const merged = { ...addresses, ...next }
    setAddressesState(merged)
    try{ localStorage.setItem(STORAGE_KEY, JSON.stringify(merged)) }catch(e){}
  }

  return (
    <AddressContext.Provider value={{ addresses, setAddresses }}>
      {children}
    </AddressContext.Provider>
  )
}

export default AddressProvider
