import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import styled from 'styled-components';
import Layout from '../components/Layout';
import { useAuth } from '../context/AuthContext';

const Container = styled.div`
  max-width: 1200px;
  margin: 0 auto;
  padding: ${({ theme }) => theme.spacing(3)};
  display: grid;
  gap: ${({ theme }) => theme.spacing(3)};
`;

const Panel = styled.div`
  background: #fff;
  border-radius: ${({ theme }) => theme.radii.md};
  box-shadow: ${({ theme }) => theme.shadow};
  padding: 16px;
`;

const Table = styled.table`
  width: 100%;
  border-collapse: collapse;
  th, td { padding: 8px; border-bottom: 1px solid #eee; text-align: left; }
  th { cursor: pointer; }
`;

export default function Admin() {
  const { state } = useAuth();
  const [sweets, setSweets] = useState([]);
  const [sort, setSort] = useState('name');
  const [dir, setDir] = useState('asc');

  useEffect(() => { loadProducts(); }, []);

  async function loadProducts() {
    try {
      const { client } = await import('../api/client');
      client.defaults.headers.common['Authorization'] = `Bearer ${state.token}`;
      const res = await client.get('/sweets', { params: { page: 1, limit: 50 } });
      setSweets(res.data.items);
    } catch {}
  }

  async function removeProduct(id) {
    try {
      if (!window.confirm('Delete this sweet?')) return;
      const { client } = await import('../api/client');
      client.defaults.headers.common['Authorization'] = `Bearer ${state.token}`;
      await client.delete(`/sweets/${id}`);
      setSweets(prev => prev.filter(s => s._id !== id));
    } catch {}
  }

  function sortBy(field) {
    if (sort === field) setDir(dir === 'asc' ? 'desc' : 'asc'); else setSort(field);
  }

  const sorted = [...sweets].sort((a, b) => {
    const va = a[sort]; const vb = b[sort];
    const cmp = va > vb ? 1 : va < vb ? -1 : 0;
    return dir === 'asc' ? cmp : -cmp;
  });

  const totals = {
    count: sweets.length,
    inventory: sweets.reduce((acc, s) => acc + s.quantity, 0),
    value: sweets.reduce((acc, s) => acc + s.quantity * s.price, 0).toFixed(2)
  };

  return (
    <Layout>
      <Container>
        <Panel>
          <h3>System Analytics</h3>
          <div style={{ display: 'flex', gap: 24 }}>
            <div>Products: {totals.count}</div>
            <div>Units in stock: {totals.inventory}</div>
            <div>Inventory value: ${totals.value}</div>
          </div>
        </Panel>
        <Panel>
          <h3>Product Inventory Management</h3>
          <div style={{ marginBottom: 12 }}>
            <Link to="/admin/sweets/new">Add New Sweet</Link>
          </div>
          <Table aria-label="Products table">
            <thead>
              <tr>
                <th onClick={() => sortBy('name')}>Name</th>
                <th onClick={() => sortBy('category')}>Category</th>
                <th onClick={() => sortBy('price')}>Price</th>
                <th onClick={() => sortBy('quantity')}>Quantity</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {sorted.map(s => (
                <tr key={s._id}>
                  <td>{s.name}</td>
                  <td>{s.category}</td>
                  <td>${s.price.toFixed(2)}</td>
                  <td>{s.quantity}</td>
                  <td>
                    <Link to={`/admin/sweets/${s._id}/edit`} style={{ marginRight: 12 }}>Edit</Link>
                    <button onClick={() => removeProduct(s._id)} aria-label={`Delete ${s.name}`}>Delete</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </Table>
        </Panel>
        <Panel>
          <h3>User Management</h3>
          <div style={{ marginBottom: 12 }}>
            <a href="/admin/users/new">Create Admin Account</a>
          </div>
          <div>Admins can manage users here (UI scaffold).</div>
        </Panel>
        <Panel>
          <h3>Order Tracking</h3>
          <div>Track orders and statuses (UI scaffold).</div>
        </Panel>
        <Panel>
          <h3>Content Moderation</h3>
          <div>Moderate reviews or listings (UI scaffold).</div>
        </Panel>
      </Container>
    </Layout>
  );
}