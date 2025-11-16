import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useState } from 'react';
import styled from 'styled-components';
import { useAuth } from '../context/AuthContext';
import { useCart } from '../context/CartContext';

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
  backdrop-filter: saturate(120%) blur(6px);
  transition: background-color .2s ease, box-shadow .2s ease;
  @media (max-width: ${({ theme }) => theme.breakpoints.md}) {
    display: none;
  }
`;

const Brand = styled(Link)`
  color: ${({ theme }) => theme.colors.primary};
  text-decoration: none;
  font-weight: 700;
  font-size: 20px;
  letter-spacing: .3px;
`;

const Nav = styled.nav`
  display: flex;
  gap: ${({ theme }) => theme.spacing(2)};
  a { 
    text-decoration: none; 
    color: ${({ theme }) => theme.colors.text};
    padding: 10px 12px;
    border-radius: ${({ theme }) => theme.radii.sm};
    transition: background-color .2s ease, transform .2s ease;
  }
  a[aria-current="page"] { background: rgba(0,0,0,0.06); }
  a:focus-visible { outline: 2px solid ${({ theme }) => theme.colors.primary}; outline-offset: 2px; }
`;

const Tools = styled.div`
  display: flex;
  gap: ${({ theme }) => theme.spacing(2)};
  align-items: center;
  position: relative;
`;

const SearchInput = styled.input`
  padding: ${({ theme }) => theme.spacing(1)};
  border-radius: ${({ theme }) => theme.radii.sm};
  border: 1px solid ${({ theme }) => theme.colors.muted};
  min-height: 40px;
  transition: border-color .2s ease, box-shadow .2s ease;
  &:focus { border-color: ${({ theme }) => theme.colors.primary}; box-shadow: 0 0 0 3px rgba(255,107,107,.2); }
`;

const CartButton = styled.button`
  appearance: none;
  background: none;
  border: 1px solid ${({ theme }) => theme.colors.muted};
  border-radius: ${({ theme }) => theme.radii.sm};
  padding: 8px 12px;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  min-height: 40px;
  transition: border-color .2s ease, box-shadow .2s ease;
  &:focus-visible { outline: 2px solid ${({ theme }) => theme.colors.primary}; outline-offset: 2px; }
`;

const Badge = styled.span`
  min-width: 20px;
  height: 20px;
  padding: 0 6px;
  border-radius: 10px;
  background: ${({ theme }) => theme.colors.primary};
  color: #fff;
  font-size: 12px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
`;

const CartPopover = styled.div`
  position: absolute;
  right: 0;
  top: calc(100% + 8px);
  width: 280px;
  max-height: 300px;
  overflow: auto;
  background: #fff;
  border: 1px solid ${({ theme }) => theme.colors.muted};
  border-radius: ${({ theme }) => theme.radii.md};
  box-shadow: ${({ theme }) => theme.shadow};
  padding: 12px;
  z-index: 30;
`;

const Main = styled.main`
  min-height: 100vh;
  @media (max-width: ${({ theme }) => theme.breakpoints.md}) {
    padding-bottom: calc(64px + env(safe-area-inset-bottom));
  }
`;

const BottomBar = styled.nav`
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  height: 64px;
  background: ${({ theme }) => theme.colors.bg};
  box-shadow: 0 -8px 24px rgba(0,0,0,0.08);
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  align-items: stretch;
  z-index: 20;
  padding-bottom: env(safe-area-inset-bottom);
  @media (min-width: ${({ theme }) => theme.breakpoints.md}) {
    display: none;
  }
`;

const BottomItem = styled.button`
  appearance: none;
  background: none;
  border: 0;
  width: 100%;
  color: ${({ theme }) => theme.colors.text};
  font: inherit;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  transition: background-color .2s ease, transform .1s ease;
  min-height: 64px;
  &:active { transform: scale(.98); }
  &[data-active="true"] { background: rgba(0,0,0,0.06); }
  &:focus-visible { outline: 2px solid ${({ theme }) => theme.colors.primary}; outline-offset: -2px; }
`;

const BottomLink = styled(Link)`
  text-decoration: none;
  color: inherit;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  min-height: 64px;
  width: 100%;
`;

export default function Layout({ children, onSearch }) {
  const { state, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [showMobileSearch, setShowMobileSearch] = useState(false);
  const [showCart, setShowCart] = useState(false);
  const { state: cart, clear } = useCart();
  const isActive = (path) => location.pathname === path;
  return (
    <>
      <Header aria-label="Top navigation">
        <Brand to="/">SweetShop</Brand>
        <Nav role="navigation" aria-label="Primary">
          <Link to="/" aria-current={isActive('/') ? 'page' : undefined}>Home</Link>
          <Link to="/about" aria-current={isActive('/about') ? 'page' : undefined}>About</Link>
          <Link to="/profile" aria-current={isActive('/profile') ? 'page' : undefined}>Profile</Link>
          {state.user?.role === 'admin' && (
            <Link to="/admin" aria-current={isActive('/admin') ? 'page' : undefined}>Admin</Link>
          )}
        </Nav>
        <Tools>
          <SearchInput aria-label="Search" placeholder="Search sweets" onChange={(e) => onSearch?.(e.target.value)} />
          <CartButton aria-label="Cart" onClick={() => setShowCart(v => !v)}>
            <span>Cart</span>
            <Badge aria-label="Items in cart">{cart.items.length}</Badge>
          </CartButton>
          {state.user ? (
            <button aria-label="Logout" onClick={() => { logout(); navigate('/login'); }}>Logout</button>
          ) : (
            <>
              <Link to="/login">Login</Link>
              <Link to="/signup" aria-current={isActive('/signup') ? 'page' : undefined}>Signup</Link>
            </>
          )}
          {showCart && (
            <CartPopover role="dialog" aria-label="Cart items">
              {cart.items.length === 0 ? (
                <div>No items</div>
              ) : (
                <div style={{ display: 'grid', gap: 8 }}>
                  {cart.items.map(i => (
                    <div key={i._id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                      <div>{i.name}</div>
                      <div>x{i.qty}</div>
                    </div>
                  ))}
                  <button onClick={() => clear()}>Clear</button>
                </div>
              )}
            </CartPopover>
          )}
        </Tools>
      </Header>
      <Main>{children}</Main>
      <BottomBar role="navigation" aria-label="Bottom navigation">
        <BottomLink to="/" aria-label="Home" aria-current={isActive('/') ? 'page' : undefined}>
          <span>Home</span>
        </BottomLink>
        <BottomItem aria-label="Search" onClick={() => setShowMobileSearch((v) => !v)} data-active={showMobileSearch}>
          <span>Search</span>
        </BottomItem>
        <BottomLink to="/profile" aria-label="Profile" aria-current={isActive('/profile') ? 'page' : undefined}>
          <span>Profile</span>
        </BottomLink>
        {state.user?.role === 'admin' ? (
          <BottomLink to="/admin" aria-label="Admin" aria-current={isActive('/admin') ? 'page' : undefined}>
            <span>Admin</span>
          </BottomLink>
        ) : (
          state.user ? (
            <BottomItem aria-label="Logout" onClick={() => { logout(); navigate('/login'); }}>
              <span>Logout</span>
            </BottomItem>
          ) : (
            <BottomLink to="/login" aria-label="Login" aria-current={isActive('/login') ? 'page' : undefined}>
              <span>Login</span>
            </BottomLink>
          )
        )}
      </BottomBar>
      {showMobileSearch && (
        <div style={{ position: 'fixed', left: 0, right: 0, bottom: '64px', padding: '12px 16px', background: '#fff', boxShadow: '0 -8px 24px rgba(0,0,0,0.08)', zIndex: 19 }}>
          <SearchInput aria-label="Search" placeholder="Search sweets" autoFocus onChange={(e) => onSearch?.(e.target.value)} />
        </div>
      )}
    </>
  );
}