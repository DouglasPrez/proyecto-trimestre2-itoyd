import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Navbar from './components/Navbar'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import SearchPage from './pages/SearchPage'
import ReservationPage from './pages/ReservationPage'
import VoucherPage from './pages/VoucherPage'
import MyReservationsPage from './pages/MyReservationsPage'
import CancelPage from './pages/CancelPage'
import AdminDashboard from './pages/AdminDashboard'
import SpaceConfigPage from './pages/SpaceConfigPage'

function ProtectedRoute({ children, adminOnly = false }: { children: React.ReactNode; adminOnly?: boolean }) {
  const { user, isAdmin } = useAuth()
  if (!user) return <Navigate to="/login" replace />
  if (adminOnly && !isAdmin) return <Navigate to="/" replace />
  return <>{children}</>
}

function AppRoutes() {
  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      <main className="max-w-6xl mx-auto px-4 py-6">
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/" element={<SearchPage />} />
          <Route path="/reserve/:spaceId/:date/:startTime" element={
            <ProtectedRoute><ReservationPage /></ProtectedRoute>
          } />
          <Route path="/voucher/:reservationId" element={
            <ProtectedRoute><VoucherPage /></ProtectedRoute>
          } />
          <Route path="/reservations" element={
            <ProtectedRoute><MyReservationsPage /></ProtectedRoute>
          } />
          <Route path="/reservations/:id/cancel" element={
            <ProtectedRoute><CancelPage /></ProtectedRoute>
          } />
          <Route path="/admin" element={
            <ProtectedRoute adminOnly><AdminDashboard /></ProtectedRoute>
          } />
          <Route path="/admin/spaces/:spaceId/config" element={
            <ProtectedRoute adminOnly><SpaceConfigPage /></ProtectedRoute>
          } />
          <Route path="/admin/spaces/new" element={
            <ProtectedRoute adminOnly><SpaceConfigPage /></ProtectedRoute>
          } />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <AppRoutes />
      </AuthProvider>
    </BrowserRouter>
  )
}
