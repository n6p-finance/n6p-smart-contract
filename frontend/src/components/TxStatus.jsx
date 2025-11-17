import React from 'react'

export default function TxStatus({ status, error, txHash, gasEstimate }){
  if(!status && !error && !txHash) return null

  const colors = {
    estimating: '#ffb800',
    signing: '#0066cc',
    submitted: '#0066cc',
    confirmed: '#00cc00',
    error: '#cc0000'
  }

  return (
    <div style={{
      marginTop: 8,
      padding: 8,
      borderRadius: 4,
      backgroundColor: '#f0f0f0',
      borderLeft: `4px solid ${colors[status] || '#999'}`
    }}>
      {status === 'estimating' && <div>⏳ Estimating gas...</div>}
      {status === 'signing' && <div>🔐 Waiting for signature...</div>}
      {status === 'submitted' && <div>📤 Submitted! Tx: <code style={{fontSize:11}}>{txHash}</code></div>}
      {status === 'confirmed' && <div>✅ Confirmed! Tx: <code style={{fontSize:11}}>{txHash}</code></div>}
      {error && <div style={{color:'#cc0000'}}>❌ Error: {error}</div>}
      {gasEstimate && (
        <div style={{marginTop:6,fontSize:12,opacity:0.8}}>
          Gas: {gasEstimate.gas} | Price: {gasEstimate.gasPrice} gwei | Cost: {gasEstimate.gasCost} ETH
        </div>
      )}
    </div>
  )
}
