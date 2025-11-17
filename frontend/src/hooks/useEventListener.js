import { useEffect, useState, useRef } from 'react'

export default function useEventListener(contract, eventName, filters = {}){
  const [events, setEvents] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const listenerRef = useRef(null)

  useEffect(() => {
    if(!contract || !eventName) return

    setLoading(true)
    setError(null)

    try {
      // fetch past events
      const eventFilter = contract.filters[eventName] ? contract.filters[eventName](filters) : null
      if(eventFilter) {
        contract.queryFilter(eventFilter, -1000).then(pastEvents => {
          setEvents(pastEvents.reverse())
          setLoading(false)

          // listen for new events
          const listener = (...args) => {
            const event = args[args.length - 1]
            setEvents(prev => [event, ...prev])
          }

          listenerRef.current = listener
          contract.on(eventFilter, listener)
        }).catch(e => {
          setError('Failed to fetch events: ' + e.message)
          setLoading(false)
        })
      }
    } catch (e) {
      setError('Event setup failed: ' + e.message)
      setLoading(false)
    }

    return () => {
      if(listenerRef.current && contract) {
        contract.removeAllListeners()
      }
    }
  }, [contract, eventName])

  return { events, loading, error }
}
