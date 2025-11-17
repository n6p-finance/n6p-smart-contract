import React from 'react'
import { Link } from 'react-router-dom'

export default function Navigation(){
  return (
    <nav style={{
      padding: 12,
      backgroundColor: '#2c3e50',
      color: 'white',
      marginBottom: 16,
      borderRadius: 4,
      display: 'flex',
      gap: 16,
      flexWrap: 'wrap'
    }}>
      <Link to="/" style={{color: 'white', textDecoration: 'none', fontWeight: 'bold'}}>Home</Link>
      <Link to="/vault" style={{color: 'white', textDecoration: 'none'}}>Vault Details</Link>
      <Link to="/registry" style={{color: 'white', textDecoration: 'none'}}>Registry Mgmt</Link>
      <Link to="/strategies" style={{color: 'white', textDecoration: 'none'}}>Strategies</Link>
      <Link to="/events" style={{color: 'white', textDecoration: 'none'}}>Events</Link>
    </nav>
  )
}
