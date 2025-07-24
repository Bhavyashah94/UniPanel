import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import Flow from './App'
import RealtimeComponent from './test'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <RealtimeComponent />
    <Flow />
  </StrictMode>,
)
