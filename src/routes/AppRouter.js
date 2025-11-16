import { Suspense, lazy } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import Spinner from '../components/Spinner';
import ProtectedRoute from '../components/ProtectedRoute';
import { AuthProvider } from '../context/AuthContext';

const Home = lazy(() => import('../pages/Home'));
const About = lazy(() => import('../pages/About'));
const NotFound = lazy(() => import('../pages/NotFound'));
const Login = lazy(() => import('../pages/Login'));
const Signup = lazy(() => import('../pages/Signup'));
const Profile = lazy(() => import('../pages/Profile'));
const Admin = lazy(() => import('../pages/Admin'));
const AddSweet = lazy(() => import('../pages/AddSweet'));
const CreateAdmin = lazy(() => import('../pages/CreateAdmin'));
const EditSweet = lazy(() => import('../pages/EditSweet'));

export default function AppRouter() {
  return (
    <Suspense fallback={<Spinner />}> 
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/about" element={<About />} />
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<Signup />} />
        <Route path="/profile" element={<ProtectedRoute><Profile /></ProtectedRoute>} />
        <Route path="/admin" element={<ProtectedRoute admin><Admin /></ProtectedRoute>} />
        <Route path="/admin/sweets/new" element={<ProtectedRoute admin><AddSweet /></ProtectedRoute>} />
        <Route path="/admin/sweets/:id/edit" element={<ProtectedRoute admin><EditSweet /></ProtectedRoute>} />
        <Route path="/admin/users/new" element={<ProtectedRoute admin><CreateAdmin /></ProtectedRoute>} />
        <Route path="/404" element={<NotFound />} />
        <Route path="*" element={<Navigate to="/404" replace />} />
      </Routes>
    </Suspense>
  );
}