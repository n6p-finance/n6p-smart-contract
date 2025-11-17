import React, { useState } from 'react'
import useEventListener from '../hooks/useEventListener'

export default function EventViewer({ contract, eventName, description = '' }){
  const { events, loading, error } = useEventListener(contract, eventName)
  const [expanded, setExpanded] = useState(false)

  if(!contract || !eventName) return null

  return (
    <div style={{marginTop:8, padding:8, backgroundColor:'#f5f5f5', borderRadius:4}}>
      <div 
        onClick={() => setExpanded(!expanded)} 
        style={{cursor:'pointer', fontWeight:'bold'}}
      >
        {expanded ? '▼' : '▶'} {eventName} {description && `(${description})`}
        {events.length > 0 && <span style={{marginLeft:8, fontSize:12, opacity:0.7}}>({events.length} events)</span>}
      </div>

      {loading && <div style={{marginTop:4, fontSize:12}}>Loading events...</div>}
      {error && <div style={{marginTop:4, fontSize:12, color:'#cc0000'}}>Error: {error}</div>}

      {expanded && events.length === 0 && !loading && (
        <div style={{marginTop:4, fontSize:12, opacity:0.6}}>No events found</div>
      )}

      {expanded && events.map((evt, idx) => (
        <div key={idx} style={{marginTop:6, padding:6, backgroundColor:'white', borderRadius:3, fontSize:11, fontFamily:'monospace'}}>
          <div><strong>Block:</strong> {evt.blockNumber} | <strong>Tx:</strong> {evt.transactionHash.slice(0,12)}...</div>
          {evt.args && Object.entries(evt.args).map(([key, val]) => (
            <div key={key}>
              <strong>{key}:</strong> {typeof val === 'object' ? val.toString() : String(val).slice(0, 50)}
            </div>
          ))}
        </div>
      ))}
    </div>
  )
}
