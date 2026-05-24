import { useState, useEffect, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { Clock, CreditCard, AlertCircle } from 'lucide-react'
import api from '../api/client'
import type { SpaceAvailability, Reservation } from '../api/client'

function Countdown({ expiresAt }: { expiresAt: string }) {
  const [secs, setSecs] = useState(0)

  useEffect(() => {
    const calc = () => {
      const diff = Math.max(0, Math.floor((new Date(expiresAt).getTime() - Date.now()) / 1000))
      setSecs(diff)
    }
    calc()
    const id = setInterval(calc, 1000)
    return () => clearInterval(id)
  }, [expiresAt])

  const m = Math.floor(secs / 60)
  const s = secs % 60
  return (
    <span className={`font-mono font-bold ${secs < 120 ? 'text-red-600' : 'text-orange-600'}`}>
      {m}:{s.toString().padStart(2, '0')}
    </span>
  )
}

export default function ReservationPage() {
  const { spaceId, date, startTime } = useParams<{ spaceId: string; date: string; startTime: string }>()
  const navigate = useNavigate()

  const [availability, setAvailability] = useState<SpaceAvailability | null>(null)
  const [reservation, setReservation] = useState<Reservation | null>(null)
  const [card, setCard] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [step, setStep] = useState<'loading' | 'lock' | 'pay'>('loading')

  const decodedStart = decodeURIComponent(startTime || '')

  const loadAvailability = useCallback(async () => {
    const { data } = await api.get<SpaceAvailability>(`/availability/${spaceId}/${date}`)
    setAvailability(data)
  }, [spaceId, date])

  const createLock = useCallback(async () => {
    try {
      const { data } = await api.post<Reservation>('/reservations', {
        space_id: Number(spaceId),
        start_time: decodedStart,
      })
      setReservation(data)
      setStep('pay')
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { detail?: string } } }).response?.data?.detail
      setError(msg || 'No se pudo reservar el espacio')
      setStep('lock')
    }
  }, [spaceId, decodedStart])

  useEffect(() => {
    loadAvailability().then(() => {
      setStep('lock')
      createLock()
    })
  }, [loadAvailability, createLock])

  const handleConfirm = async () => {
    if (!reservation || card.length < 4) return
    setLoading(true)
    setError('')
    try {
      await api.put(`/reservations/${reservation.id}/confirm`, {
        payment_method_last4: card.slice(-4),
      })
      navigate(`/voucher/${reservation.id}`)
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { detail?: string } } }).response?.data?.detail
      setError(msg || 'Error al procesar el pago')
    } finally {
      setLoading(false)
    }
  }

  if (step === 'loading') {
    return <div className="card text-center py-12 text-gray-500">Preparando reserva...</div>
  }

  if (error && !reservation) {
    return (
      <div className="card text-center py-12">
        <AlertCircle size={40} className="mx-auto text-red-500 mb-3" />
        <p className="text-red-600 font-medium">{error}</p>
        <button className="btn-secondary mt-4" onClick={() => navigate(-1)}>Volver</button>
      </div>
    )
  }

  const space = availability
  const startDt = new Date(decodedStart)
  const endDt = space ? new Date(startDt.getTime() + space.duration_minutes * 60000) : null
  const amount = space ? (space.price_per_hour * (space.duration_minutes / 60)) : 0

  return (
    <div className="max-w-lg mx-auto space-y-4">
      <h1 className="text-2xl font-bold">Confirmar reserva</h1>

      {/* Summary */}
      <div className="card space-y-3">
        <h2 className="font-semibold text-gray-700">Resumen</h2>
        <div className="text-sm space-y-2">
          <div className="flex justify-between">
            <span className="text-gray-500">Complejo</span>
            <span className="font-medium">{space?.complex_name}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-500">Espacio</span>
            <span className="font-medium">{space?.space_name}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-500">Fecha</span>
            <span className="font-medium">{format(startDt, "EEEE d 'de' MMMM yyyy", { locale: es })}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-500">Horario</span>
            <span className="font-medium">
              {format(startDt, 'HH:mm')} – {endDt ? format(endDt, 'HH:mm') : ''}
            </span>
          </div>
          <hr />
          <div className="flex justify-between font-bold text-base">
            <span>Total</span>
            <span className="text-blue-700">Q{amount.toFixed(2)}</span>
          </div>
        </div>
      </div>

      {/* Countdown */}
      {reservation?.expires_at && (
        <div className="bg-orange-50 border border-orange-200 rounded-xl p-4 flex items-center gap-3">
          <Clock size={20} className="text-orange-500 shrink-0" />
          <div className="text-sm">
            <p className="text-orange-700">El espacio está reservado para ti por <Countdown expiresAt={reservation.expires_at} /></p>
            <p className="text-orange-500 text-xs mt-0.5">Completa el pago antes de que expire</p>
          </div>
        </div>
      )}

      {/* Payment */}
      <div className="card space-y-4">
        <h2 className="font-semibold text-gray-700 flex items-center gap-2">
          <CreditCard size={18} />Método de pago (simulado)
        </h2>
        <div>
          <label className="block text-sm font-medium mb-1">Número de tarjeta</label>
          <input
            className="input font-mono"
            placeholder="1234 5678 9012 3456"
            value={card}
            onChange={e => setCard(e.target.value.replace(/\D/g, '').slice(0, 16))}
            maxLength={16}
          />
          <p className="text-xs text-gray-400 mt-1">Ingresa cualquier número para la demo</p>
        </div>

        {error && <p className="text-red-600 text-sm">{error}</p>}

        <button
          className="btn-primary w-full text-base py-3"
          onClick={handleConfirm}
          disabled={loading || card.length < 4}
        >
          {loading ? 'Procesando...' : `Confirmar y pagar Q${amount.toFixed(2)}`}
        </button>

        <button className="btn-secondary w-full" onClick={() => navigate(-1)}>
          Cancelar
        </button>
      </div>
    </div>
  )
}
