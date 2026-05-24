import { useEffect, useState, FormEvent } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Save, ArrowLeft } from 'lucide-react'
import api from '../api/client'
import type { Space } from '../api/client'
import { useAuth } from '../context/AuthContext'

const SPORTS = ['futbol', 'tenis', 'basquetbol', 'padel', 'voleybol', 'otro']
const DURATIONS = [30, 45, 60, 90, 120]

const defaults = {
  name: '',
  sport_type: 'tenis',
  duration_minutes: 60,
  cleaning_minutes: 15,
  price_per_hour: 75,
  open_time: '07:00',
  close_time: '22:00',
  cancel_free_hours: 4,
  cancel_penalty_pct: 50,
  cancel_no_refund_hours: 1,
}

export default function SpaceConfigPage() {
  const { spaceId } = useParams<{ spaceId: string }>()
  const isNew = !spaceId || spaceId === 'new'
  const { user } = useAuth()
  const navigate = useNavigate()

  const [form, setForm] = useState(defaults)
  const [loading, setLoading] = useState(!isNew)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)

  useEffect(() => {
    if (isNew) return
    api.get<Space>(`/admin/spaces/${spaceId}`).then(({ data }) => {
      setForm({
        name: data.name,
        sport_type: data.sport_type,
        duration_minutes: data.duration_minutes,
        cleaning_minutes: data.cleaning_minutes,
        price_per_hour: data.price_per_hour,
        open_time: data.open_time,
        close_time: data.close_time,
        cancel_free_hours: data.cancel_free_hours,
        cancel_penalty_pct: data.cancel_penalty_pct,
        cancel_no_refund_hours: data.cancel_no_refund_hours,
      })
    }).finally(() => setLoading(false))
  }, [spaceId, isNew])

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setError('')
    try {
      if (isNew) {
        await api.post('/admin/spaces', { ...form, complex_id: user?.complex_id })
      } else {
        await api.put(`/admin/spaces/${spaceId}`, form)
      }
      setSuccess(true)
      setTimeout(() => navigate('/admin'), 1200)
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { detail?: string } } }).response?.data?.detail
      setError(msg || 'Error al guardar')
    } finally {
      setSaving(false)
    }
  }

  const set = (key: keyof typeof defaults, value: string | number) =>
    setForm(f => ({ ...f, [key]: value }))

  if (loading) return <div className="card text-center py-12 text-gray-400">Cargando...</div>

  return (
    <div className="max-w-lg mx-auto space-y-5">
      <div className="flex items-center gap-3">
        <button onClick={() => navigate('/admin')} className="btn-secondary p-2">
          <ArrowLeft size={18} />
        </button>
        <h1 className="text-2xl font-bold">{isNew ? 'Nuevo espacio' : 'Configurar espacio'}</h1>
      </div>

      {success && (
        <div className="bg-green-50 text-green-700 rounded-lg p-3 text-sm">Guardado correctamente. Redirigiendo...</div>
      )}
      {error && (
        <div className="bg-red-50 text-red-700 rounded-lg p-3 text-sm">{error}</div>
      )}

      <form onSubmit={handleSubmit} className="space-y-5">
        {/* Basic info */}
        <div className="card space-y-4">
          <h2 className="font-semibold text-gray-700">Información básica</h2>
          <div>
            <label className="block text-sm font-medium mb-1">Nombre del espacio</label>
            <input className="input" value={form.name} onChange={e => set('name', e.target.value)} required placeholder="Tenis No. 3" />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Tipo de deporte</label>
            <select className="input" value={form.sport_type} onChange={e => set('sport_type', e.target.value)}>
              {SPORTS.map(s => <option key={s} value={s}>{s.charAt(0).toUpperCase() + s.slice(1)}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Precio por hora (Q)</label>
            <input className="input" type="number" min={0} value={form.price_per_hour} onChange={e => set('price_per_hour', Number(e.target.value))} required />
          </div>
        </div>

        {/* Schedule */}
        <div className="card space-y-4">
          <h2 className="font-semibold text-gray-700">Horario y duración</h2>
          <div>
            <label className="block text-sm font-medium mb-2">Duración del slot</label>
            <div className="flex gap-2 flex-wrap">
              {DURATIONS.map(d => (
                <button
                  key={d}
                  type="button"
                  onClick={() => set('duration_minutes', d)}
                  className={`px-4 py-2 rounded-lg border text-sm font-medium transition-colors ${form.duration_minutes === d ? 'bg-blue-600 text-white border-blue-600' : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'}`}
                >
                  {d} min
                </button>
              ))}
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium mb-1">Apertura</label>
              <input className="input" type="time" value={form.open_time} onChange={e => set('open_time', e.target.value)} />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Cierre</label>
              <input className="input" type="time" value={form.close_time} onChange={e => set('close_time', e.target.value)} />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Tiempo de limpieza entre reservas (minutos)</label>
            <input className="input" type="number" min={0} max={60} value={form.cleaning_minutes} onChange={e => set('cleaning_minutes', Number(e.target.value))} />
          </div>
        </div>

        {/* Cancellation policy */}
        <div className="card space-y-4">
          <h2 className="font-semibold text-gray-700">Política de cancelación</h2>
          <div>
            <label className="block text-sm font-medium mb-1">Cancelación libre hasta (horas antes)</label>
            <input className="input" type="number" min={0} value={form.cancel_free_hours} onChange={e => set('cancel_free_hours', Number(e.target.value))} />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Penalidad entre zona media (%)</label>
            <input className="input" type="number" min={0} max={100} value={form.cancel_penalty_pct} onChange={e => set('cancel_penalty_pct', Number(e.target.value))} />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Sin reembolso si faltan menos de (horas)</label>
            <input className="input" type="number" min={0} value={form.cancel_no_refund_hours} onChange={e => set('cancel_no_refund_hours', Number(e.target.value))} />
          </div>
          <div className="bg-gray-50 rounded-lg p-3 text-xs text-gray-500 space-y-1">
            <p>Ejemplo con valores actuales:</p>
            <p>• Más de {form.cancel_free_hours}h antes → Reembolso 100%</p>
            <p>• Entre {form.cancel_no_refund_hours}h y {form.cancel_free_hours}h → Reembolso {100 - form.cancel_penalty_pct}%</p>
            <p>• Menos de {form.cancel_no_refund_hours}h antes → Sin reembolso</p>
          </div>
        </div>

        <button type="submit" className="btn-primary w-full flex items-center justify-center gap-2 py-3 text-base" disabled={saving}>
          <Save size={18} />
          {saving ? 'Guardando...' : 'Guardar espacio'}
        </button>
      </form>
    </div>
  )
}
