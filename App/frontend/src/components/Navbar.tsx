import { Link, useNavigate } from 'react-router-dom'
import { Trophy, Calendar, LogOut, User, LayoutDashboard } from 'lucide-react'
import { useAuth } from '../context/AuthContext'

export default function Navbar() {
  const { user, logout, isAdmin } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <nav className="bg-blue-700 text-white shadow-md">
      <div className="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
        <Link to="/" className="flex items-center gap-2 font-bold text-lg tracking-tight">
          <Trophy size={20} />
          SportSpace
        </Link>

        <div className="flex items-center gap-4 text-sm">
          {user ? (
            <>
              {isAdmin ? (
                <Link to="/admin" className="flex items-center gap-1 hover:text-blue-200 transition-colors">
                  <LayoutDashboard size={16} />
                  <span>Admin</span>
                </Link>
              ) : (
                <Link to="/reservations" className="flex items-center gap-1 hover:text-blue-200 transition-colors">
                  <Calendar size={16} />
                  <span>Mis reservas</span>
                </Link>
              )}
              <span className="text-blue-200 flex items-center gap-1">
                <User size={15} />
                {user.name.split(' ')[0]}
              </span>
              <button onClick={handleLogout} className="flex items-center gap-1 hover:text-blue-200 transition-colors">
                <LogOut size={15} />
                Salir
              </button>
            </>
          ) : (
            <>
              <Link to="/login" className="hover:text-blue-200 transition-colors">Ingresar</Link>
              <Link to="/register" className="bg-white text-blue-700 px-3 py-1 rounded-lg font-medium hover:bg-blue-50 transition-colors">
                Registrarse
              </Link>
            </>
          )}
        </div>
      </div>
    </nav>
  )
}
