import { useEffect, useMemo, useState } from 'react';
import styled from 'styled-components';
import { useApp } from '../context/AppContext';
import Layout from '../components/Layout';
import SweetCard from '../components/SweetCard';
import { useCart } from '../context/CartContext';

const Wrapper = styled.div`
  padding: ${({ theme }) => theme.spacing(3)};
  max-width: 1200px;
  margin: 0 auto;
  display: grid;
  gap: ${({ theme }) => theme.spacing(3)};
`;

const Title = styled.h1`
  font-size: 28px;
`;

const Grid = styled.div`
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: ${({ theme }) => theme.spacing(2)};
  @media (max-width: ${({ theme }) => theme.breakpoints.lg}) {
    grid-template-columns: repeat(3, 1fr);
  }
  @media (max-width: ${({ theme }) => theme.breakpoints.md}) {
    grid-template-columns: repeat(2, 1fr);
  }
  @media (max-width: ${({ theme }) => theme.breakpoints.sm}) {
    grid-template-columns: 1fr;
  }
`;

export default function Home() {
  const { state, dispatch } = useApp();
  const [sweets, setSweets] = useState([]);
  const [query, setQuery] = useState('');
  const [category, setCategory] = useState('');

  useEffect(() => { fetchSweets(); }, []);

  async function fetchSweets() {
    dispatch({ type: 'loading:start' });
    try {
      const { client } = await import('../api/client');
      const res = await client.get('/sweets', { params: { page: 1, limit: 20 } });
      setSweets(res.data.items);
      dispatch({ type: 'error:clear' });
    } catch {
      dispatch({ type: 'error:set', payload: 'Failed to load sweets' });
    } finally {
      dispatch({ type: 'loading:end' });
    }
  }

  const filtered = useMemo(() => sweets.filter(s => {
    const matchesName = s.name.toLowerCase().includes(query.toLowerCase());
    const matchesCat = category ? s.category === category : true;
    return matchesName && matchesCat;
  }), [sweets, query, category]);

  const { add } = useCart();
  function onAddToCart(s) { add(s); }

  return (
    <Layout onSearch={setQuery}>
      <Wrapper>
        <Title>Featured Sweets</Title>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <label>Category</label>
          <select value={category} onChange={(e) => setCategory(e.target.value)}>
            <option value="">All</option>
            <option value="Candy">Candy</option>
            <option value="Chocolate">Chocolate</option>
            <option value="Sugar">Sugar</option>
          </select>
        </div>
        {state.error && <div role="alert" style={{ color: 'red' }}>{state.error}</div>}
        {state.loading && <div>Loading...</div>}
        <Grid>
          {filtered.map(s => (
            <SweetCard key={s._id} sweet={s} onAdd={onAddToCart} />
          ))}
        </Grid>
      </Wrapper>
    </Layout>
  );
}