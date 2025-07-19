import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import Flow from './App'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Flow />
  </StrictMode>,
)
