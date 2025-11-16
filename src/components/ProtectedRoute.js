import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function ProtectedRoute({ children, admin }) {
  const { state } = useAuth();
  if (!state.token) return <Navigate to="/login" replace />;
  if (admin && state.user?.role !== 'admin') return <Navigate to="/" replace />;
  return children;
}