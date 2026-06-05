import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, MapPin, Calendar, Trophy } from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import api from '../api/client'
import type { SpaceAvailability, TimeSlot } from '../api/client'
import { useAuth } from '../context/AuthContext'

const SPORTS = [
  { value: '', label: 'Todos los deportes' },
  { value: 'futbol', label: 'Fútbol' },
  { value: 'tenis', label: 'Tenis' },
  { value: 'basquetbol', label: 'Básquetbol' },
  { value: 'padel', label: 'Pádel' },
]

const ZONES = [
  { value: '', label: 'Todas las zonas' },
  { value: 'Zona Norte', label: 'Zona Norte' },
  { value: 'Zona Sur', label: 'Zona Sur' },
  { value: 'Zona Este', label: 'Zona Este' },
  { value: 'Zona Oeste', label: 'Zona Oeste' },
]

function slotClass(status: TimeSlot['status']) {
  switch (status) {
    case 'available': return 'slot-available'
    case 'reserved': return 'slot-reserved'
    case 'pending': return 'slot-pending'
    case 'blocked': return 'slot-blocked'
  }
}

function slotLabel(status: TimeSlot['status']) {
  switch (status) {
    case 'available': return 'Libre'
    case 'reserved': return 'Ocupado'
    case 'pending': return 'En proceso'
    case 'blocked': return 'Bloqueado'
  }
}

export default function SearchPage() {
  const [sport, setSport] = useState('')
  const [date, setDate] = useState(format(new Date(), 'yyyy-MM-dd'))
  const [zone, setZone] = useState('')
  const [results, setResults] = useState<SpaceAvailability[]>([])
  const [loading, setLoading] = useState(false)
  const [searched, setSearched] = useState(false)
  const { user } = useAuth()
  const navigate = useNavigate()

  const search = async (d: string, s: string, z: string) => {
    setLoading(true)
    setSearched(true)
    try {
      const params: Record<string, string> = { date: d }
      if (s) params.sport = s
      if (z) params.zone = z
      const { data } = await api.get('/availability/search', { params })
      setResults(data)
    } finally {
      setLoading(false)
    }
  }

  const handleSearch = () => search(date, sport, zone)

  // Carga los resultados automáticamente al abrir la página
  useEffect(() => { search(date, sport, zone) }, [])

  const handleSlotClick = (space: SpaceAvailability, slot: TimeSlot) => {
    if (slot.status !== 'available') return
    if (!user) {
      navigate('/login')
      return
    }
    navigate(`/reserve/${space.space_id}/${date}/${encodeURIComponent(slot.start_dt)}`)
  }

  return (
    <div className="space-y-6">
      {/* Hero */}
      <div className="bg-blue-700 text-white rounded-2xl p-8 text-center">
        <div className="flex justify-center mb-3">
          <Trophy size={40} />
        </div>
        <h1 className="text-3xl font-bold mb-2">Reserva tu cancha</h1>
        <p className="text-blue-200">Disponibilidad en tiempo real. Confirmación inmediata.</p>
      </div>

      {/* Search bar */}
      <div className="card">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Deporte</label>
            <select className="input" value={sport} onChange={e => setSport(e.target.value)}>
              {SPORTS.map(s => <option key={s.value} value={s.value}>{s.label}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              <Calendar size={14} className="inline mr-1" />Fecha
            </label>
            <input className="input" type="date" value={date} onChange={e => setDate(e.target.value)} min={format(new Date(), 'yyyy-MM-dd')} />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              <MapPin size={14} className="inline mr-1" />Zona
            </label>
            <select className="input" value={zone} onChange={e => setZone(e.target.value)}>
              {ZONES.map(z => <option key={z.value} value={z.value}>{z.label}</option>)}
            </select>
          </div>
        </div>
        <button className="btn-primary w-full flex items-center justify-center gap-2" onClick={handleSearch} disabled={loading}>
          <Search size={16} />
          {loading ? 'Buscando...' : 'Buscar disponibilidad'}
        </button>
      </div>

      {/* Legend */}
      {searched && (
        <div className="flex flex-wrap gap-3 text-xs font-medium">
          <span className="flex items-center gap-1"><span className="w-3 h-3 rounded bg-green-300 inline-block" />Disponible</span>
          <span className="flex items-center gap-1"><span className="w-3 h-3 rounded bg-blue-300 inline-block" />Ocupado</span>
          <span className="flex items-center gap-1"><span className="w-3 h-3 rounded bg-yellow-300 inline-block" />En proceso</span>
          <span className="flex items-center gap-1"><span className="w-3 h-3 rounded bg-gray-300 inline-block" />Bloqueado</span>
        </div>
      )}

      {/* Results */}
      {searched && !loading && results.length === 0 && (
        <div className="card text-center text-gray-500 py-10">
          No se encontraron espacios disponibles para los filtros seleccionados.
        </div>
      )}

      {results.map(space => (
        <div key={space.space_id} className="card">
          <div className="flex items-start justify-between mb-4">
            <div>
              <h2 className="font-bold text-lg">{space.space_name}</h2>
              <p className="text-sm text-gray-500">
                <MapPin size={13} className="inline mr-1" />
                {space.complex_name} · {space.zone}
              </p>
            </div>
            <div className="text-right">
              <span className="text-lg font-bold text-blue-700">Q{space.price_per_hour.toFixed(2)}</span>
              <p className="text-xs text-gray-500">por hora</p>
            </div>
          </div>

          <div className="overflow-x-auto">
            <div className="flex gap-2 min-w-max pb-2">
              {space.slots.map(slot => (
                <button
                  key={slot.start}
                  onClick={() => handleSlotClick(space, slot)}
                  className={`px-3 py-2 rounded-lg text-xs font-medium text-center min-w-[72px] ${slotClass(slot.status)}`}
                  title={slotLabel(slot.status)}
                >
                  <div>{slot.start}</div>
                  <div className="text-[10px] opacity-75">{slotLabel(slot.status)}</div>
                </button>
              ))}
            </div>
          </div>

          <div className="mt-3 text-xs text-gray-400">
            {format(new Date(date + 'T12:00:00'), "EEEE d 'de' MMMM yyyy", { locale: es })}
          </div>
        </div>
      ))}
    </div>
  )
}
