import styled from 'styled-components';
import Layout from '../components/Layout';
import { useAuth } from '../context/AuthContext';

const Container = styled.div`
  max-width: 1000px;
  margin: 0 auto;
  padding: ${({ theme }) => theme.spacing(3)};
  display: grid;
  gap: ${({ theme }) => theme.spacing(3)};
`;

const Card = styled.div`
  background: #fff;
  padding: 16px;
  border-radius: ${({ theme }) => theme.radii.md};
  box-shadow: ${({ theme }) => theme.shadow};
`;

export default function Profile() {
  const { state } = useAuth();
  return (
    <Layout>
      <Container>
        <Card aria-label="User info">
          <h3>Profile</h3>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <img src={`https://api.dicebear.com/7.x/initials/svg?seed=${state.user?.email || 'U'}`} alt="Profile" width={64} height={64} />
            <div>
              <div>{state.user?.email}</div>
              <div>Role: {state.user?.role}</div>
              <button>Edit</button>
            </div>
          </div>
        </Card>
        <Card aria-label="Order history">
          <h3>Order History</h3>
          <div>No orders yet.</div>
        </Card>
        <Card aria-label="Saved items and settings">
          <h3>Favorites / Payment / Settings</h3>
          <div>Manage saved items and account settings here.</div>
        </Card>
      </Container>
    </Layout>
  );
}