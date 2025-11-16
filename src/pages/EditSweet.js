import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import styled from 'styled-components';
import Layout from '../components/Layout';
import { useAuth } from '../context/AuthContext';

const Form = styled.form`
  max-width: 620px;
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

export default function EditSweet() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { state } = useAuth();
  const [name, setName] = useState('');
  const [category, setCategory] = useState('Candy');
  const [price, setPrice] = useState('');
  const [quantity, setQuantity] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [ingredients, setIngredients] = useState('');
  const [descHtml, setDescHtml] = useState('');
  const [status, setStatus] = useState('');

  useEffect(() => { load(); }, []);

  async function load() {
    try {
      const { client } = await import('../api/client');
      client.defaults.headers.common['Authorization'] = `Bearer ${state.token}`;
      const res = await client.get(`/sweets`, { params: { page: 1, limit: 1, name: '' } });
      const { client: c } = await import('../api/client');
      c.defaults.headers.common['Authorization'] = `Bearer ${state.token}`;
      const item = (await c.get(`/sweets/search`, { params: { name: '' } })).data.items.find(x => x._id === id);
      if (item) {
        setName(item.name); setCategory(item.category); setPrice(String(item.price)); setQuantity(String(item.quantity));
        setImageUrl(item.imageUrl || ''); setIngredients((item.ingredients || []).join(', ')); setDescHtml(item.description || '');
      }
    } catch {}
  }

  async function onSubmit(e) { e.preventDefault();
    setStatus('');
    try {
      const { client } = await import('../api/client');
      client.defaults.headers.common['Authorization'] = `Bearer ${state.token}`;
      const ing = ingredients.split(',').map(s => s.trim()).filter(Boolean);
      await client.put(`/sweets/${id}`, {
        name,
        category,
        price: parseFloat(price),
        quantity: parseInt(quantity, 10),
        description: descHtml,
        ingredients: ing,
        imageUrl
      });
      setStatus('Sweet updated');
      navigate('/admin');
    } catch { setStatus('Update failed'); }
  }

  return (
    <Layout>
      <Form onSubmit={onSubmit} aria-label="Edit sweet form">
        <h2>Edit Sweet</h2>
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
        <label>Image URL</label>
        <Input value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} />
        <label>Ingredients (comma separated)</label>
        <Input value={ingredients} onChange={(e) => setIngredients(e.target.value)} />
        <label>Description</label>
        <div style={{ border: '1px solid #ddd', borderRadius: 6 }}>
          <div style={{ display: 'flex', gap: 8, padding: 8 }}>
            <button type="button" onClick={() => document.execCommand('bold')}>Bold</button>
            <button type="button" onClick={() => document.execCommand('italic')}>Italic</button>
            <button type="button" onClick={() => document.execCommand('underline')}>Underline</button>
          </div>
          <div
            contentEditable
            style={{ minHeight: 120, padding: 12 }}
            onInput={(e) => setDescHtml(e.currentTarget.innerHTML)}
            dangerouslySetInnerHTML={{ __html: descHtml }}
          />
        </div>
        <Button>Save</Button>
        {status && <div role="alert">{status}</div>}
      </Form>
    </Layout>
  );
}