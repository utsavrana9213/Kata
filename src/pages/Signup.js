import { useState } from 'react';
import styled from 'styled-components';
import { Link, useNavigate } from 'react-router-dom';
import Layout from '../components/Layout';
import { useAuth } from '../context/AuthContext';

const Form = styled.form`
  max-width: 480px;
  margin: 40px auto;
  background: #fff;
  padding: 24px;
  border-radius: ${({ theme }) => theme.radii.md};
  box-shadow: ${({ theme }) => theme.shadow};
  display: grid;
  gap: 12px;
`;

const Input = styled.input`
  padding: 12px;
  border: 1px solid ${({ theme }) => theme.colors.muted};
  border-radius: ${({ theme }) => theme.radii.sm};
`;

const Button = styled.button`
  padding: 12px;
  background: ${({ theme }) => theme.colors.secondary};
  color: #333;
  border: none;
  border-radius: ${({ theme }) => theme.radii.sm};
  cursor: pointer;
  transition: transform .1s ease;
  &:disabled { opacity: .6; cursor: default; }
  &:active { transform: scale(.98); }
`;

export default function Signup() {
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [errors, setErrors] = useState({});
  const navigate = useNavigate();
  const { state, register } = useAuth();
  const [adminStatus, setAdminStatus] = useState('');
  async function registerAdmin() {
    setAdminStatus('');
    try {
      const { client } = await import('../api/client');
      if (state.token) client.defaults.headers.common['Authorization'] = `Bearer ${state.token}`;
      await client.post('/auth/register-admin', { email, password });
      navigate('/login');
    } catch (e) {
      const code = e?.response?.data?.error;
      const msg = code === 'user_exists'
        ? 'Email already registered'
        : code === 'unauthorized'
        ? 'Login as admin to create more admins'
        : code === 'forbidden'
        ? 'Only admins can create new admins'
        : 'Failed to create admin';
      setAdminStatus(msg);
    }
  }

  function validate() {
    const errs = {};
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) errs.email = 'Invalid email';
    if (password.length < 8) errs.password = 'Minimum 8 characters';
    if (password !== confirm) errs.confirm = 'Passwords must match';
    if (!username.trim()) errs.username = 'Username required';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }

  async function onSubmit(e) { e.preventDefault();
    if (!validate()) return;
    const ok = await register({ email, password });
    if (ok) navigate('/login');
  }

  return (
    <Layout>
      <Form onSubmit={onSubmit} aria-label="Create account form">
        <h2>Create Account</h2>
        <label>Username</label>
        <Input value={username} onChange={(e) => { setUsername(e.target.value); validate(); }} aria-invalid={!!errors.username} />
        {errors.username && <span role="alert" style={{ color: 'red' }}>{errors.username}</span>}
        <label>Email</label>
        <Input type="email" value={email} onChange={(e) => { setEmail(e.target.value); validate(); }} aria-invalid={!!errors.email} />
        {errors.email && <span role="alert" style={{ color: 'red' }}>{errors.email}</span>}
        <label>Password</label>
        <Input type="password" value={password} onChange={(e) => { setPassword(e.target.value); validate(); }} aria-invalid={!!errors.password} />
        {errors.password && <span role="alert" style={{ color: 'red' }}>{errors.password}</span>}
        <label>Confirm Password</label>
        <Input type="password" value={confirm} onChange={(e) => { setConfirm(e.target.value); validate(); }} aria-invalid={!!errors.confirm} />
        {errors.confirm && <span role="alert" style={{ color: 'red' }}>{errors.confirm}</span>}
        <Button disabled={state.loading}>{state.loading ? 'Signing up...' : 'Sign Up'}</Button>
        <Button type="button" onClick={registerAdmin} disabled={state.loading}>
          Create as Admin
        </Button>
        {adminStatus && <div role="alert" style={{ color: 'red' }}>{adminStatus}</div>}
        {state.error && <div role="alert" style={{ color: 'red' }}>{state.error}</div>}
        <div>
          Already have an account? <Link to="/login">Login</Link>
        </div>
      </Form>
    </Layout>
  );
}