import axios from 'axios'

const api = axios.create({ baseURL: '/api' })

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

export default api

// ── Types mirroring backend schemas ──────────────────────────────────────────

export interface User {
  id: number
  email: string
  name: string
  role: 'USER' | 'ADMIN'
  complex_id: number | null
}

export interface Complex {
  id: number
  name: string
  zone: string
  address: string | null
}

export interface Space {
  id: number
  complex_id: number
  name: string
  sport_type: string
  duration_minutes: number
  cleaning_minutes: number
  price_per_hour: number
  open_time: string
  close_time: string
  is_active: boolean
  cancel_free_hours: number
  cancel_penalty_pct: number
  cancel_no_refund_hours: number
}

export interface TimeSlot {
  start: string
  end: string
  start_dt: string
  end_dt: string
  status: 'available' | 'reserved' | 'pending' | 'blocked'
  reservation_code: string | null
  reservation_id: number | null
}

export interface SpaceAvailability {
  space_id: number
  space_name: string
  sport_type: string
  complex_id: number
  complex_name: string
  zone: string
  date: string
  price_per_hour: number
  duration_minutes: number
  slots: TimeSlot[]
}

export interface Reservation {
  id: number
  reservation_code: string | null
  space_id: number
  user_id: number
  start_time: string
  end_time: string
  status: 'PENDING' | 'CONFIRMED' | 'CANCELLED' | 'EXPIRED'
  amount_paid: number | null
  payment_method_last4: string | null
  expires_at: string | null
  created_at: string | null
  cancelled_at: string | null
  refund_amount: number | null
  space: Space | null
  user: User | null
}

export interface AgendaSlot {
  start: string
  end: string
  start_dt: string
  end_dt: string
  status: 'available' | 'reserved' | 'pending' | 'blocked'
  user_name: string | null
  reservation_code: string | null
  reservation_id: number | null
  block_reason: string | null
  block_id: number | null
}

export interface SpaceAgenda {
  space: Space
  slots: AgendaSlot[]
}

export interface DayAgenda {
  date: string
  complex: Complex
  spaces: SpaceAgenda[]
}

export interface SpaceUtilization {
  space_id: number
  space_name: string
  sport_type: string
  total_slots: number
  reserved_slots: number
  occupancy_pct: number
}

export interface MonthlyReport {
  complex_id: number
  complex_name: string
  year: number
  month: number
  spaces: SpaceUtilization[]
}
