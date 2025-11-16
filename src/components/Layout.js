import { Link, useNavigate } from 'react-router-dom';
import styled from 'styled-components';
import { useAuth } from '../context/AuthContext';

const Header = styled.header`
  background: ${({ theme }) => theme.colors.bg};
  box-shadow: ${({ theme }) => theme.shadow};
  padding: ${({ theme }) => theme.spacing(2)};
  display: flex;
  align-items: center;
  justify-content: space-between;
  position: sticky;
  top: 0;
  z-index: 10;
`;

const Brand = styled(Link)`
  color: ${({ theme }) => theme.colors.primary};
  text-decoration: none;
  font-weight: 700;
  font-size: 20px;
`;

const Nav = styled.nav`
  display: flex;
  gap: ${({ theme }) => theme.spacing(2)};
  a { text-decoration: none; color: ${({ theme }) => theme.colors.text}; }
`;

const Tools = styled.div`
  display: flex;
  gap: ${({ theme }) => theme.spacing(2)};
`;

const SearchInput = styled.input`
  padding: ${({ theme }) => theme.spacing(1)};
  border-radius: ${({ theme }) => theme.radii.sm};
  border: 1px solid ${({ theme }) => theme.colors.muted};
`;

export default function Layout({ children, onSearch }) {
  const { state, logout } = useAuth();
  const navigate = useNavigate();
  return (
    <>
      <Header>
        <Brand to="/">SweetShop</Brand>
        <Nav>
          <Link to="/">Home</Link>
          <Link to="/profile">Profile</Link>
          {state.user?.role === 'admin' && <Link to="/admin">Admin</Link>}
        </Nav>
        <Tools>
          <SearchInput aria-label="Search" placeholder="Search sweets" onChange={(e) => onSearch?.(e.target.value)} />
          {state.user ? (
            <button onClick={() => { logout(); navigate('/login'); }}>Logout</button>
          ) : (
            <Link to="/login">Login</Link>
          )}
        </Tools>
      </Header>
      <main>{children}</main>
    </>
  );
}