import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { Plus, Eye, XCircle } from 'lucide-react'
import api from '../api/client'
import type { Reservation } from '../api/client'

const STATUS_CONFIG = {
  CONFIRMED: { label: 'CONFIRMADA', cls: 'bg-green-100 text-green-700' },
  PENDING:   { label: 'EN PROCESO', cls: 'bg-yellow-100 text-yellow-700' },
  CANCELLED: { label: 'CANCELADA',  cls: 'bg-red-100 text-red-700' },
  EXPIRED:   { label: 'EXPIRADA',   cls: 'bg-gray-100 text-gray-500' },
}

function ReservationCard({ res }: { res: Reservation }) {
  const start = new Date(res.start_time)
  const end = new Date(res.end_time)
  const cfg = STATUS_CONFIG[res.status]
  const isCancellable = res.status === 'CONFIRMED' || res.status === 'PENDING'

  return (
    <div className="card hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap mb-1">
            <span className="font-mono text-sm font-bold text-blue-700">{res.reservation_code ?? `#${res.id}`}</span>
            <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${cfg.cls}`}>{cfg.label}</span>
          </div>
          <p className="font-medium text-gray-800">{res.space?.name ?? '—'}</p>
          <p className="text-sm text-gray-500">{res.space ? '' : ''}</p>
          <p className="text-sm text-gray-600 mt-1">
            {format(start, "EEE d 'de' MMM yyyy", { locale: es })} · {format(start, 'HH:mm')}–{format(end, 'HH:mm')}
          </p>
          {res.amount_paid != null && (
            <p className="text-sm font-semibold text-blue-700 mt-1">Q{res.amount_paid.toFixed(2)}</p>
          )}
          {res.status === 'CANCELLED' && res.refund_amount != null && (
            <p className="text-xs text-gray-400">Reembolso: Q{res.refund_amount.toFixed(2)}</p>
          )}
        </div>
      </div>
      <div className="flex gap-2 mt-4 flex-wrap">
        <Link to={`/voucher/${res.id}`} className="btn-secondary flex items-center gap-1 text-xs py-1.5 px-3">
          <Eye size={14} />Ver detalle
        </Link>
        {isCancellable && (
          <Link to={`/reservations/${res.id}/cancel`} className="flex items-center gap-1 text-xs py-1.5 px-3 border border-red-300 text-red-600 rounded-lg hover:bg-red-50 transition-colors">
            <XCircle size={14} />Cancelar
          </Link>
        )}
      </div>
    </div>
  )
}

export default function MyReservationsPage() {
  const [reservations, setReservations] = useState<Reservation[]>([])
  const [loading, setLoading] = useState(true)
  const [tab, setTab] = useState<'upcoming' | 'history'>('upcoming')

  useEffect(() => {
    api.get<Reservation[]>('/reservations/me').then(({ data }) => {
      setReservations(data)
    }).finally(() => setLoading(false))
  }, [])

  const now = new Date()
  const upcoming = reservations.filter(r =>
    (r.status === 'CONFIRMED' || r.status === 'PENDING') && new Date(r.start_time) >= now
  )
  const history = reservations.filter(r =>
    r.status === 'CANCELLED' || r.status === 'EXPIRED' || new Date(r.start_time) < now
  )

  const displayed = tab === 'upcoming' ? upcoming : history

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Mis Reservas</h1>
        <Link to="/" className="btn-primary flex items-center gap-2 text-sm">
          <Plus size={16} />Nueva reserva
        </Link>
      </div>

      <div className="flex gap-1 bg-gray-100 rounded-xl p-1 w-fit">
        {(['upcoming', 'history'] as const).map(t => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-colors ${tab === t ? 'bg-white shadow text-blue-700' : 'text-gray-500 hover:text-gray-700'}`}
          >
            {t === 'upcoming' ? 'Próximas' : 'Historial'}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="card text-center py-10 text-gray-400">Cargando reservas...</div>
      ) : displayed.length === 0 ? (
        <div className="card text-center py-10 text-gray-400">
          {tab === 'upcoming' ? 'No tienes reservas próximas.' : 'Sin historial de reservas.'}
        </div>
      ) : (
        <div className="space-y-4">
          {displayed.map(r => <ReservationCard key={r.id} res={r} />)}
        </div>
      )}
    </div>
  )
}
