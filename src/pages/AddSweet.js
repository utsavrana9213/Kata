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

export default function AddSweet() {
  const [name, setName] = useState('');
  const [category, setCategory] = useState('Candy');
  const [price, setPrice] = useState('');
  const [quantity, setQuantity] = useState('');
  const [status, setStatus] = useState('');
  const { state } = useAuth();

  async function onSubmit(e) { e.preventDefault();
    setStatus('');
    try {
      const { client } = await import('../api/client');
      client.defaults.headers.common['Authorization'] = `Bearer ${state.token}`;
      await client.post('/sweets', { name, category, price: parseFloat(price), quantity: parseInt(quantity, 10) });
      setStatus('Sweet created successfully');
      setName(''); setPrice(''); setQuantity('');
    } catch (err) {
      setStatus('Failed to create sweet');
    }
  }

  return (
    <Layout>
      <Form onSubmit={onSubmit} aria-label="Add sweet form">
        <h2>Add Sweet</h2>
        <label>Name</label>
        <Input value={name} onChange={(e) => setName(e.target.value)} required />
        <label>Category</label>
        <select value={category} onChange={(e) => setCategory(e.target.value)}>
          <option>Candy</option>
          <option>Chocolate</option>
          <option>Sugar</option>
        </select>
        <label>Price</label>
        <Input type="number" step="0.01" value={price} onChange={(e) => setPrice(e.target.value)} required />
        <label>Quantity</label>
        <Input type="number" value={quantity} onChange={(e) => setQuantity(e.target.value)} required />
        <Button disabled={!state.token}>Create</Button>
        {status && <div role="alert">{status}</div>}
      </Form>
    </Layout>
  );
}