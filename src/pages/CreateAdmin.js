import { useState } from 'react';
import styled from 'styled-components';
import Layout from '../components/Layout';
import { useAuth } from '../context/AuthContext';

const Wrapper = styled.div`
  max-width: 400px;
  margin: 0 auto;
  padding: ${({ theme }) => theme.spacing(3)};
  display: grid;
  gap: 16px;
`;

const Title = styled.h2``;

const Input = styled.input`
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
`;

const Button = styled.button`
  padding: 8px;
  background: ${({ theme }) => theme.colors.primary};
  color: #fff;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  &:disabled { background: #aaa; }
`;

export default function CreateAdmin() {
  const { state } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState('');

  async function handleSubmit(e) {
    e.preventDefault();
    setLoading(true);
    setStatus('');
    try {
      const { client } = await import('../api/client');
      client.defaults.headers.common['Authorization'] = `Bearer ${state.token}`;
      await client.post('/auth/register-admin', { email, password });
      setStatus('Admin created successfully');
      setEmail('');
      setPassword('');
    } catch (e) {
      const code = e?.response?.data?.error;
      const msg = code === 'user_exists'
        ? 'Email already registered'
        : code === 'unauthorized'
        ? 'Login as admin to create more admins'
        : code === 'forbidden'
        ? 'Only admins can create new admins'
        : 'Failed to create admin';
      setStatus(msg);
    } finally {
      setLoading(false);
    }
  }

  return (
    <Layout>
      <Wrapper>
        <Title>Create Admin Account</Title>
        <form onSubmit={handleSubmit}>
          <Input
            type="email"
            placeholder="Admin email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <Input
            type="password"
            placeholder="Password (min 8 chars)"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          <Button disabled={loading}>{loading ? 'Creating...' : 'Create Admin'}</Button>
          {status && <div role="alert" style={{ color: status.includes('Failed') ? 'red' : 'green' }}>{status}</div>}
        </form>
      </Wrapper>
    </Layout>
  );
}