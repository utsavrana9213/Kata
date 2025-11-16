import { useState } from 'react';
import styled from 'styled-components';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import Layout from '../components/Layout';

const Form = styled.form`
  max-width: 420px;
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
  background: ${({ theme }) => theme.colors.primary};
  color: #fff;
  border: none;
  border-radius: ${({ theme }) => theme.radii.sm};
  cursor: pointer;
  transition: transform .1s ease;
  &:disabled { opacity: .6; cursor: default; }
  &:active { transform: scale(.98); }
`;

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [remember, setRemember] = useState(true);
  const navigate = useNavigate();
  const { state, login } = useAuth();

  async function onSubmit(e) { e.preventDefault();
    const ok = await login({ email, password, remember });
    if (ok) navigate('/');
  }

  return (
    <Layout>
      <Form onSubmit={onSubmit} aria-label="Login form">
        <h2>Login</h2>
        <label>Email or Username</label>
        <Input value={email} onChange={(e) => setEmail(e.target.value)} required />
        <label>Password</label>
        <Input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        <label>
          <input type="checkbox" checked={remember} onChange={(e) => setRemember(e.target.checked)} /> Remember Me
        </label>
        <Button disabled={state.loading}>{state.loading ? 'Logging in...' : 'Login'}</Button>
        {state.error && <div role="alert" style={{ color: 'red' }}>{state.error}</div>}
        <div>
          <Link to="/forgot">Forgot Password</Link>
        </div>
        <div>
          No account? <Link to="/signup">Create one</Link>
        </div>
      </Form>
    </Layout>
  );
}