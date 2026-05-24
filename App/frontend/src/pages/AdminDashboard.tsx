import { useEffect, useState, useCallback } from 'react'
import { Link } from 'react-router-dom'
import { format, addDays, subDays } from 'date-fns'
import { es } from 'date-fns/locale'
import { ChevronLeft, ChevronRight, Plus, Settings, Lock, Unlock } from 'lucide-react'
import api from '../api/client'
import type { DayAgenda, AgendaSlot, MonthlyReport } from '../api/client'
import { useAuth } from '../context/AuthContext'

function slotStyle(status: AgendaSlot['status']) {
  switch (status) {
    case 'available': return 'bg-green-50 text-green-700 border-green-200'
    case 'reserved':  return 'bg-blue-100 text-blue-800 border-blue-300'
    case 'pending':   return 'bg-yellow-100 text-yellow-700 border-yellow-300'
    case 'blocked':   return 'bg-gray-200 text-gray-600 border-gray-300'
  }
}

function slotIcon(status: AgendaSlot['status']) {
  if (status === 'blocked') return <Lock size={10} className="inline mr-0.5" />
  if (status === 'pending') return <span className="mr-0.5">~</span>
  if (status === 'reserved') return <span className="mr-0.5">■</span>
  return null
}

export default function AdminDashboard() {
  const { user } = useAuth()
  const [date, setDate] = useState(format(new Date(), 'yyyy-MM-dd'))
  const [agenda, setAgenda] = useState<DayAgenda | null>(null)
  const [report, setReport] = useState<MonthlyReport | null>(null)
  const [loading, setLoading] = useState(true)
  const [tab, setTab] = useState<'agenda' | 'report'>('agenda')
  const [blockModal, setBlockModal] = useState<{ spaceId: number; start: string; end: string } | null>(null)
  const [blockReason, setBlockReason] = useState('Mantenimiento')
  const [blockLoading, setBlockLoading] = useState(false)

  const complexId = user?.complex_id

  const loadAgenda = useCallback(async () => {
    if (!complexId) return
    setLoading(true)
    try {
      const { data } = await api.get<DayAgenda>(`/admin/agenda/${complexId}/${date}`)
      setAgenda(data)
    } finally {
      setLoading(false)
    }
  }, [complexId, date])

  const loadReport = useCallback(async () => {
    if (!complexId) return
    const now = new Date()
    const { data } = await api.get<MonthlyReport>(`/admin/report/${complexId}/${now.getFullYear()}/${now.getMonth() + 1}`)
    setReport(data)
  }, [complexId])

  useEffect(() => {
    if (tab === 'agenda') loadAgenda()
    else loadReport()
  }, [tab, loadAgenda, loadReport])

  const prevDay = () => setDate(format(subDays(new Date(date + 'T12:00:00'), 1), 'yyyy-MM-dd'))
  const nextDay = () => setDate(format(addDays(new Date(date + 'T12:00:00'), 1), 'yyyy-MM-dd'))

  const handleSlotClick = (spaceId: number, slot: AgendaSlot) => {
    if (slot.status === 'available') {
      setBlockModal({ spaceId, start: slot.start_dt, end: slot.end_dt })
    }
  }

  const handleCreateBlock = async () => {
    if (!blockModal) return
    setBlockLoading(true)
    try {
      await api.post('/admin/blocks', {
        space_id: blockModal.spaceId,
        start_time: blockModal.start,
        end_time: blockModal.end,
        reason: blockReason,
      })
      setBlockModal(null)
      setBlockReason('Mantenimiento')
      loadAgenda()
    } finally {
      setBlockLoading(false)
    }
  }

  const handleDeleteBlock = async (blockId: number) => {
    if (!confirm('¿Eliminar este bloqueo?')) return
    await api.delete(`/admin/blocks/${blockId}`)
    loadAgenda()
  }

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Panel de administración</h1>
          {agenda && <p className="text-gray-500 text-sm">{agenda.complex.name}</p>}
        </div>
        <div className="flex gap-2">
          <Link to="/admin/spaces/new" className="btn-secondary flex items-center gap-2 text-sm">
            <Plus size={16} />Nuevo espacio
          </Link>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 bg-gray-100 rounded-xl p-1 w-fit">
        {(['agenda', 'report'] as const).map(t => (
          <button key={t} onClick={() => setTab(t)}
            className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-colors ${tab === t ? 'bg-white shadow text-blue-700' : 'text-gray-500 hover:text-gray-700'}`}>
            {t === 'agenda' ? 'Agenda' : 'Reporte mensual'}
          </button>
        ))}
      </div>

      {tab === 'agenda' && (
        <>
          {/* Date nav */}
          <div className="flex items-center gap-4">
            <button onClick={prevDay} className="btn-secondary p-2"><ChevronLeft size={18} /></button>
            <span className="font-semibold">
              {format(new Date(date + 'T12:00:00'), "EEEE d 'de' MMMM yyyy", { locale: es })}
            </span>
            <button onClick={nextDay} className="btn-secondary p-2"><ChevronRight size={18} /></button>
            <button onClick={() => setDate(format(new Date(), 'yyyy-MM-dd'))} className="btn-secondary text-sm">Hoy</button>
          </div>

          {/* Legend */}
          <div className="flex flex-wrap gap-3 text-xs font-medium">
            <span className="flex items-center gap-1 px-2 py-1 bg-green-50 rounded border border-green-200 text-green-700">Libre</span>
            <span className="flex items-center gap-1 px-2 py-1 bg-blue-100 rounded border border-blue-300 text-blue-800">■ Reservado</span>
            <span className="flex items-center gap-1 px-2 py-1 bg-yellow-100 rounded border border-yellow-300 text-yellow-700">~ En proceso</span>
            <span className="flex items-center gap-1 px-2 py-1 bg-gray-200 rounded border border-gray-300 text-gray-600"><Lock size={10} />Bloqueado</span>
          </div>

          {loading ? (
            <div className="card text-center py-12 text-gray-400">Cargando agenda...</div>
          ) : agenda && agenda.spaces.length === 0 ? (
            <div className="card text-center py-12 text-gray-400">
              No hay espacios configurados. <Link to="/admin/spaces/new" className="text-blue-600">Crear espacio</Link>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full text-sm">
                <thead>
                  <tr className="bg-gray-50 border-b">
                    <th className="text-left py-2 px-3 font-semibold text-gray-600 w-20">Hora</th>
                    {agenda?.spaces.map(sa => (
                      <th key={sa.space.id} className="py-2 px-3 font-semibold text-gray-600 text-left min-w-[140px]">
                        <div>{sa.space.name}</div>
                        <div className="text-xs font-normal text-gray-400 capitalize">{sa.space.sport_type}</div>
                        <Link to={`/admin/spaces/${sa.space.id}/config`} className="text-blue-500 text-xs flex items-center gap-0.5 mt-0.5 hover:underline">
                          <Settings size={10} />Config
                        </Link>
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {agenda?.spaces[0]?.slots.map((_, slotIdx) => (
                    <tr key={slotIdx} className="border-b hover:bg-gray-50">
                      <td className="py-1.5 px-3 text-gray-500 font-mono text-xs whitespace-nowrap">
                        {agenda.spaces[0].slots[slotIdx].start}
                      </td>
                      {agenda?.spaces.map(sa => {
                        const slot = sa.slots[slotIdx]
                        if (!slot) return <td key={sa.space.id} />
                        return (
                          <td key={sa.space.id} className="py-1 px-2">
                            <div
                              className={`rounded-lg border px-2 py-1 text-xs cursor-pointer ${slotStyle(slot.status)}`}
                              onClick={() => handleSlotClick(sa.space.id, slot)}
                              title={slot.status === 'available' ? 'Clic para bloquear' : undefined}
                            >
                              {slotIcon(slot.status)}
                              {slot.status === 'reserved' || slot.status === 'pending'
                                ? <span>{slot.user_name ?? slot.reservation_code}</span>
                                : slot.status === 'blocked'
                                ? (
                                  <span className="flex items-center gap-1">
                                    {slot.block_reason}
                                    <button
                                      onClick={e => { e.stopPropagation(); handleDeleteBlock(slot.block_id!) }}
                                      className="ml-1 text-gray-400 hover:text-red-500"
                                    >
                                      <Unlock size={10} />
                                    </button>
                                  </span>
                                )
                                : <span className="text-green-600">Libre</span>
                              }
                            </div>
                          </td>
                        )
                      })}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      )}

      {tab === 'report' && (
        <div className="card">
          <h2 className="font-bold mb-4">
            Utilización {report ? `${report.complex_name} — ${new Date(report.year, report.month - 1).toLocaleString('es', { month: 'long' })} ${report.year}` : '...'}
          </h2>
          {report ? (
            <div className="space-y-4">
              {report.spaces.map(s => (
                <div key={s.space_id} className="space-y-1">
                  <div className="flex justify-between text-sm">
                    <span className="font-medium">{s.space_name} <span className="text-gray-400 capitalize">({s.sport_type})</span></span>
                    <span className="text-blue-700 font-semibold">{s.occupancy_pct}%</span>
                  </div>
                  <div className="h-3 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-blue-500 rounded-full transition-all"
                      style={{ width: `${s.occupancy_pct}%` }}
                    />
                  </div>
                  <p className="text-xs text-gray-400">{s.reserved_slots} / {s.total_slots} slots ocupados</p>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-gray-400 text-center py-8">Cargando reporte...</div>
          )}
        </div>
      )}

      {/* Block modal */}
      {blockModal && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 w-full max-w-sm shadow-xl space-y-4">
            <h3 className="font-bold text-lg">Crear bloqueo</h3>
            <p className="text-sm text-gray-500">
              Horario: {format(new Date(blockModal.start), 'HH:mm')} – {format(new Date(blockModal.end), 'HH:mm')}
            </p>
            <div>
              <label className="block text-sm font-medium mb-1">Motivo</label>
              <input className="input" value={blockReason} onChange={e => setBlockReason(e.target.value)} />
            </div>
            <div className="flex gap-3">
              <button className="btn-secondary flex-1" onClick={() => setBlockModal(null)}>Cancelar</button>
              <button className="btn-primary flex-1" onClick={handleCreateBlock} disabled={blockLoading}>
                {blockLoading ? 'Creando...' : 'Crear bloqueo'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
