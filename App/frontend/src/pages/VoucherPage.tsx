import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { CheckCircle, Calendar, XCircle } from 'lucide-react'
import api from '../api/client'
import type { Reservation } from '../api/client'

export default function VoucherPage() {
  const { reservationId } = useParams<{ reservationId: string }>()
  const [reservation, setReservation] = useState<Reservation | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.get<Reservation>(`/reservations/${reservationId}`).then(({ data }) => {
      setReservation(data)
    }).finally(() => setLoading(false))
  }, [reservationId])

  if (loading) return <div className="card text-center py-12 text-gray-500">Cargando...</div>
  if (!reservation) return <div className="card text-center py-12 text-red-500">Reserva no encontrada</div>

  const space = reservation.space
  const start = new Date(reservation.start_time)
  const end = new Date(reservation.end_time)

  return (
    <div className="max-w-md mx-auto">
      <div className="card text-center space-y-5">
        <div className="flex flex-col items-center gap-2">
          <CheckCircle size={56} className="text-green-500" />
          <h1 className="text-2xl font-bold text-green-700">Reserva confirmada</h1>
        </div>

        <div className="bg-gray-50 rounded-xl p-5 text-left space-y-3 text-sm">
          <div className="flex justify-between">
            <span className="text-gray-500">Código</span>
            <span className="font-mono font-bold text-blue-700">{reservation.reservation_code}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-500">Complejo</span>
            <span className="font-medium">{space?.name ? space.name : '—'}</span>
          </div>
          {space && (
            <div className="flex justify-between">
              <span className="text-gray-500">Cancha</span>
              <span className="font-medium">{space.name}</span>
            </div>
          )}
          <div className="flex justify-between">
            <span className="text-gray-500">Fecha</span>
            <span className="font-medium">{format(start, "EEE d 'de' MMM yyyy", { locale: es })}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-500">Horario</span>
            <span className="font-medium">{format(start, 'HH:mm')} – {format(end, 'HH:mm')}</span>
          </div>
          <hr />
          <div className="flex justify-between font-bold">
            <span>Pagado</span>
            <span className="text-blue-700">Q{(reservation.amount_paid ?? 0).toFixed(2)}</span>
          </div>
          {reservation.payment_method_last4 && (
            <div className="flex justify-between text-gray-400 text-xs">
              <span>Tarjeta</span>
              <span>**** **** **** {reservation.payment_method_last4}</span>
            </div>
          )}
        </div>

        {reservation.user?.email && (
          <p className="text-xs text-gray-500">Confirmación enviada a: {reservation.user.email}</p>
        )}

        <div className="flex gap-3">
          <Link to="/reservations" className="btn-secondary flex-1 flex items-center justify-center gap-2">
            <Calendar size={16} />Mis reservas
          </Link>
          <Link to={`/reservations/${reservation.id}/cancel`} className="flex-1 flex items-center justify-center gap-2 text-red-600 border border-red-300 rounded-lg px-4 py-2 text-sm font-medium hover:bg-red-50 transition-colors">
            <XCircle size={16} />Cancelar
          </Link>
        </div>

        <Link to="/" className="btn-primary block">Nueva reserva</Link>
      </div>
    </div>
  )
}
