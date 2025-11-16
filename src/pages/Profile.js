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
  background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
  padding: 24px;
  border-radius: ${({ theme }) => theme.radii.md};
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.07), 0 1px 3px rgba(0, 0, 0, 0.06);
  border: 1px solid rgba(0, 0, 0, 0.05);
  transition: transform 0.2s ease, box-shadow 0.2s ease;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 12px rgba(0, 0, 0, 0.1), 0 2px 4px rgba(0, 0, 0, 0.06);
  }
`;

const CardTitle = styled.h3`
  margin: 0 0 20px 0;
  font-size: 1.5rem;
  font-weight: 600;
  color: #2c3e50;
  display: flex;
  align-items: center;
  gap: 10px;

  &::before {
    content: '';
    display: inline-block;
    width: 4px;
    height: 24px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 2px;
  }
`;

const ProfileSection = styled.div`
  display: flex;
  align-items: center;
  gap: 20px;
`;

const AvatarContainer = styled.div`
  position: relative;
  
  img {
    border-radius: 50%;
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
    border: 3px solid #fff;
    transition: transform 0.3s ease;

    &:hover {
      transform: scale(1.05);
    }
  }
`;

const UserInfo = styled.div`
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
`;

const InfoRow = styled.div`
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.95rem;
  color: #555;

  strong {
    color: #2c3e50;
    font-weight: 600;
    min-width: 60px;
  }
`;

const EmailText = styled.div`
  font-size: 1.1rem;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 4px;
`;

const Badge = styled.span`
  display: inline-block;
  padding: 4px 12px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 12px;
  font-size: 0.85rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
`;

const EditButton = styled.button`
  margin-top: 12px;
  padding: 10px 24px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
  }

  &:active {
    transform: translateY(0);
  }
`;

const EmptyState = styled.div`
  text-align: center;
  padding: 40px 20px;
  color: #95a5a6;
  font-size: 1rem;

  &::before {
    content: '📦';
    display: block;
    font-size: 3rem;
    margin-bottom: 16px;
    opacity: 0.6;
  }
`;

const SettingsGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-top: 16px;
`;

const SettingsItem = styled.div`
  padding: 16px;
  background: white;
  border-radius: 8px;
  border: 1px solid #e9ecef;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(102, 126, 234, 0.3);
  }

  div:first-child {
    font-size: 2rem;
    margin-bottom: 8px;
  }

  div:last-child {
    font-weight: 600;
    font-size: 0.9rem;
  }
`;

export default function Profile() {
  const { state } = useAuth();
  return (
    <Layout>
      <Container>
        <Card aria-label="User info">
          <CardTitle>Profile</CardTitle>
          <ProfileSection>
            <AvatarContainer>
              <img 
                src={`https://api.dicebear.com/7.x/initials/svg?seed=${state.user?.email || 'U'}`} 
                alt="Profile" 
                width={64} 
                height={64} 
              />
            </AvatarContainer>
            <UserInfo>
              <EmailText>{state.user?.email}</EmailText>
              <InfoRow>
                <strong>ID:</strong> {state.user?.id}
              </InfoRow>
              <InfoRow>
                <strong>Role:</strong> <Badge>{state.user?.role}</Badge>
              </InfoRow>
              <EditButton>Edit Profile</EditButton>
            </UserInfo>
          </ProfileSection>
        </Card>

        <Card aria-label="Order history">
          <CardTitle>Order History</CardTitle>
          <EmptyState>
            No orders yet. Start shopping to see your order history here!
          </EmptyState>
        </Card>

        <Card aria-label="Saved items and settings">
          <CardTitle>Favorites / Payment / Settings</CardTitle>
          <SettingsGrid>
            <SettingsItem>
              <div>❤️</div>
              <div>Favorites</div>
            </SettingsItem>
            <SettingsItem>
              <div>💳</div>
              <div>Payment</div>
            </SettingsItem>
            <SettingsItem>
              <div>⚙️</div>
              <div>Settings</div>
            </SettingsItem>
          </SettingsGrid>
        </Card>
      </Container>
    </Layout>
  );
}