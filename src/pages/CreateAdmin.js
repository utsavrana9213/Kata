import { useState } from 'react';
import styled from 'styled-components';
import Layout from '../components/Layout';
import { useAuth } from '../context/AuthContext';

const Form = styled.form`
  max-width: 520px;
  margin: 32px auto;
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
  &:disabled { opacity: .6; }
`;

export default function CreateAdmin() {
  const { state } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [status, setStatus] = useState('');

  async function onSubmit(e) { e.preventDefault();
    setStatus('');
    try {
      const { client } = await import('../api/client');
      client.defaults.headers.common['Authorization'] = `Bearer ${state.token}`;
      await client.post('/auth/register-admin', { email, password });
      setStatus('Admin account created');
      setEmail(''); setPassword('');
    } catch (err) {
      setStatus('Failed to create admin');
    }
  }

  return (
    <Layout>
      <Form onSubmit={onSubmit} aria-label="Create admin form">
        <h2>Create Admin Account</h2>
        <label>Email</label>
        <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        <label>Password</label>
        <Input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        <Button disabled={!state.token}>Create</Button>
        {status && <div role="alert">{status}</div>}
      </Form>
    </Layout>
  );
}