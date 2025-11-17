import { useState, useCallback } from 'react'
import { ethers } from 'ethers'

export default function useTransaction(){
  const [status, setStatus] = useState(null) // 'idle' | 'estimating' | 'signing' | 'submitted' | 'confirmed' | 'error'
  const [error, setError] = useState(null)
  const [txHash, setTxHash] = useState(null)
  const [gasEstimate, setGasEstimate] = useState(null)

  const estimateGas = useCallback(async (txObject) => {
    setStatus('estimating')
    setError(null)
    try {
      const estimate = await txObject.contract.provider.estimateGas(txObject)
      const gasPrice = await txObject.contract.provider.getGasPrice()
      const gasCost = estimate.mul(gasPrice)
      setGasEstimate({
        gas: estimate.toString(),
        gasPrice: ethers.utils.formatUnits(gasPrice, 'gwei'),
        gasCost: ethers.utils.formatEther(gasCost)
      })
      setStatus('idle')
      return { gas: estimate, gasPrice }
    } catch (e) {
      setError('Gas estimation failed: ' + e.message)
      setStatus('error')
      return null
    }
  }, [])

  const sendTransaction = useCallback(async (contractFn, args = []) => {
    setStatus('signing')
    setError(null)
    setTxHash(null)
    try {
      const tx = await contractFn(...args)
      setTxHash(tx.hash)
      setStatus('submitted')
      const receipt = await tx.wait()
      setStatus('confirmed')
      return receipt
    } catch (e) {
      setError(e.message || 'Transaction failed')
      setStatus('error')
      return null
    }
  }, [])

  const reset = useCallback(() => {
    setStatus(null)
    setError(null)
    setTxHash(null)
    setGasEstimate(null)
  }, [])

  return { status, error, txHash, gasEstimate, sendTransaction, estimateGas, reset }
}
