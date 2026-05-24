import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { AlertTriangle } from 'lucide-react'
import api from '../api/client'
import type { Reservation } from '../api/client'

function calcRefundLabel(reservation: Reservation): { label: string; amount: number; bracket: number } {
  if (!reservation.space) return { label: 'Calcular reembolso...', amount: 0, bracket: -1 }
  const space = reservation.space
  const now = new Date()
  const start = new Date(reservation.start_time)
  const hoursUntil = (start.getTime() - now.getTime()) / 3600000

  let amount = 0
  let bracket = 0

  if (hoursUntil >= space.cancel_free_hours) {
    amount = reservation.amount_paid ?? 0
    bracket = 0
    return { label: `Reembolso completo Q${amount.toFixed(2)}`, amount, bracket }
  } else if (hoursUntil >= space.cancel_no_refund_hours) {
    const pct = (100 - space.cancel_penalty_pct) / 100
    amount = Math.round((reservation.amount_paid ?? 0) * pct * 100) / 100
    bracket = 1
    return { label: `Reembolso parcial Q${amount.toFixed(2)} (${100 - space.cancel_penalty_pct}%)`, amount, bracket }
  } else {
    bracket = 2
    return { label: 'Sin reembolso', amount: 0, bracket }
  }
}

export default function CancelPage() {
  const { id } = useParams<{ id: string }>()
  const [reservation, setReservation] = useState<Reservation | null>(null)
  const [loading, setLoading] = useState(true)
  const [cancelling, setCancelling] = useState(false)
  const [error, setError] = useState('')
  const navigate = useNavigate()

  useEffect(() => {
    api.get<Reservation>(`/reservations/${id}`).then(({ data }) => {
      setReservation(data)
    }).finally(() => setLoading(false))
  }, [id])

  const handleCancel = async () => {
    if (!reservation) return
    setCancelling(true)
    setError('')
    try {
      await api.put(`/reservations/${reservation.id}/cancel`)
      navigate('/reservations')
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { detail?: string } } }).response?.data?.detail
      setError(msg || 'Error al cancelar')
    } finally {
      setCancelling(false)
    }
  }

  if (loading) return <div className="card text-center py-12 text-gray-500">Cargando...</div>
  if (!reservation || !reservation.space) return <div className="card text-center py-12 text-red-500">Reserva no encontrada</div>

  const space = reservation.space
  const start = new Date(reservation.start_time)
  const end = new Date(reservation.end_time)
  const { label: refundLabel, amount: refundAmount, bracket } = calcRefundLabel(reservation)

  const brackets = [
    {
      label: `Antes de ${space.cancel_free_hours}h del inicio`,
      desc: `Reembolso 100% (Q${(reservation.amount_paid ?? 0).toFixed(2)})`,
    },
    {
      label: `Entre ${space.cancel_no_refund_hours}h y ${space.cancel_free_hours}h del inicio`,
      desc: `Reembolso ${100 - space.cancel_penalty_pct}% (penalidad ${space.cancel_penalty_pct}%)`,
    },
    {
      label: `Menos de ${space.cancel_no_refund_hours}h del inicio`,
      desc: 'Sin reembolso',
    },
  ]

  return (
    <div className="max-w-lg mx-auto space-y-4">
      <h1 className="text-2xl font-bold">Cancelar reserva</h1>
      <p className="text-gray-500 font-mono text-sm">{reservation.reservation_code}</p>

      <div className="card text-sm space-y-2">
        <div className="flex justify-between"><span className="text-gray-500">Espacio</span><span>{space.name}</span></div>
        <div className="flex justify-between">
          <span className="text-gray-500">Fecha y hora</span>
          <span>{format(start, "d MMM yyyy", { locale: es })} · {format(start, 'HH:mm')}–{format(end, 'HH:mm')}</span>
        </div>
        <div className="flex justify-between"><span className="text-gray-500">Pagado</span><span>Q{(reservation.amount_paid ?? 0).toFixed(2)}</span></div>
      </div>

      <div className="card space-y-3">
        <h2 className="font-semibold">Política de cancelación</h2>
        {brackets.map((b, i) => (
          <div
            key={i}
            className={`flex items-start gap-3 p-3 rounded-lg border text-sm ${
              i === bracket ? 'border-blue-500 bg-blue-50' : 'border-gray-200'
            }`}
          >
            <span className={`w-4 h-4 rounded-full border-2 mt-0.5 shrink-0 ${i === bracket ? 'border-blue-600 bg-blue-600' : 'border-gray-300'}`} />
            <div>
              <p className="font-medium">{b.label}</p>
              <p className="text-gray-500">{b.desc}</p>
            </div>
          </div>
        ))}
      </div>

      <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 flex gap-3">
        <AlertTriangle size={20} className="text-amber-500 shrink-0 mt-0.5" />
        <div className="text-sm">
          <p className="font-semibold text-amber-700">Si cancelas ahora recibirás:</p>
          <p className="text-amber-600 text-lg font-bold">Q{refundAmount.toFixed(2)}</p>
          <p className="text-amber-600 text-xs">{refundLabel}</p>
        </div>
      </div>

      {error && <p className="text-red-600 text-sm">{error}</p>}

      <div className="flex gap-3">
        <button className="btn-secondary flex-1" onClick={() => navigate(-1)}>Volver</button>
        <button className="btn-danger flex-1" onClick={handleCancel} disabled={cancelling}>
          {cancelling ? 'Cancelando...' : 'Confirmar cancelación'}
        </button>
      </div>
    </div>
  )
}
