import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import styled, { keyframes } from 'styled-components';
import { useApp } from '../context/AppContext';
import { useAuth } from '../context/AuthContext';
import { useCart } from '../context/CartContext';

const Wrapper = styled.div`
  padding: 0;
  max-width: 100%;
  margin: 0 auto;
`;

const ContentWrapper = styled.div`
  padding: ${({ theme }) => `${theme?.spacing?.(4) || '32px'} ${theme?.spacing?.(3) || '24px'}`};
  max-width: 1400px;
  margin: 0 auto;
`;

const Title = styled.h2`
  font-size: clamp(28px, 4vw, 36px);
  color: #2d2d2d;
  margin-bottom: 24px;
  font-weight: 600;
  text-align: center;
  position: relative;
  &::after {
    content: '';
    display: block;
    width: 80px;
    height: 4px;
    background: linear-gradient(90deg, #ffc5d9, #b8a6d9);
    margin: 12px auto 0;
    border-radius: 2px;
  }
`;

const Grid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 28px;
  margin-top: 40px;
`;

// Color palette
const colors = {
  primary: '#ffc5d9',
  secondary: '#b8a6d9',
  tertiary: '#a8d8ea',
  accent: '#ffebb7',
  background: '#fef9f3',
  cardBg: '#ffffff',
  text: '#2d2d2d',
  textLight: '#666666',
  shadow: 'rgba(149, 157, 165, 0.15)'
};

export default function Home() {
  const { state, dispatch } = useApp();
  const navigate = useNavigate();
  const [sweets, setSweets] = useState([]);
  const [query, setQuery] = useState('');
  const [category, setCategory] = useState('');
  const { state: auth } = useAuth();
  const heroRef = useRef(null);
  const [parallax, setParallax] = useState(0);

  useEffect(() => {
    let raf = 0;
    function onScroll() {
      const y = window.scrollY || 0;
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => setParallax(y));
    }
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => { window.removeEventListener('scroll', onScroll); cancelAnimationFrame(raf); };
  }, []);

  const filtered = useMemo(() => sweets.filter(s => {
    const matchesName = s.name.toLowerCase().includes(query.toLowerCase());
    const matchesCat = category ? s.category === category : true;
    return matchesName && matchesCat;
  }), [sweets, query, category]);

  const { add, state: cartState } = useCart();
  
  useEffect(() => {
    let mounted = true;
    async function fetchSweets() {
      dispatch({ type: 'loading:start' });
      try {
        const { client } = await import('../api/client');
        if (auth.token) {
          client.defaults.headers.common['Authorization'] = `Bearer ${auth.token}`;
        }
        const res = await client.get('/sweets', { params: { page: 1, limit: 24 } });
        const items = (res.data.items || []).map(s => ({
          ...s,
          stock: s.quantity,
          imageUrl: s.imageUrl || '/sweets.jpg'
        }));
        if (mounted) setSweets(items);
        dispatch({ type: 'error:clear' });
      } catch (e) {
        dispatch({ type: 'error:set', payload: 'Failed to load sweets' });
      } finally {
        dispatch({ type: 'loading:end' });
      }
    }
    fetchSweets();
    return () => { mounted = false; };
  }, [dispatch]);

  const galleryData = [
    { key: '1', src: '/sweets.jpg', alt: 'Sweets Collection' },
    { key: '2', src: '/sweets1.jpg', alt: 'Assorted Treats' },
    { key: '3', src: '/candy.jpg', alt: 'Colorful Candy' },
    { key: '4', src: '/caramel.jpg', alt: 'Caramel Delights' },
    { key: '5', src: '/chocolate.jpg', alt: 'Chocolate Heaven' },
    { key: '6', src: '/gummies.jpg', alt: 'Gummy Collection' },
  ];

  return (
    <Wrapper>
      <TopNavigation>
        <NavContainer>
          <Logo to="/">
            <LogoIcon>🍭</LogoIcon>
            SweetHome
          </Logo>
          
          <NavLinks>
            <NavLink to="/" $active={true}>
              <NavIcon>🏠</NavIcon>
              Home
            </NavLink>
            <NavLink to="/profile">
              <NavIcon>👤</NavIcon>
              Profile
            </NavLink>
            {auth.user?.role === 'admin' && (
              <NavLink to="/admin">
                <NavIcon>⚙️</NavIcon>
                Admin
              </NavLink>
            )}
            <CartLink to="/cart">
              <NavIcon>🛒</NavIcon>
              Cart
              {cartState.items.length > 0 && (
                <CartBadge>{cartState.items.length}</CartBadge>
              )}
            </CartLink>
          </NavLinks>
        </NavContainer>
      </TopNavigation>
      
      <Hero ref={heroRef}>
        <Parallax style={{ transform: `translate3d(0, ${-parallax * 0.08}px, 0)` }} />
        <HeroInner>
          <HeroContent>
            <HeroTitle>Delight in Every Bite</HeroTitle>
            <HeroSubtitle>Discover artisan sweets crafted with love and wrapped in soft pastel elegance</HeroSubtitle>
            <HeroButton onClick={() => document.getElementById('featured')?.scrollIntoView({ behavior: 'smooth' })}>
              Explore Collection
            </HeroButton>
          </HeroContent>
          <HeroBubbles>
            {heroBubbles.map((b, i) => (
              <Bubble key={i} style={{ left: b.left, top: b.top, animationDelay: b.delay }}>
                <img src={b.src} alt="sweet" loading="lazy" />
              </Bubble>
            ))}
          </HeroBubbles>
        </HeroInner>
      </Hero>

      <ContentWrapper>
        <Section>
          <SectionTitle>Sweet Moments Gallery</SectionTitle>
          <Gallery>
            {galleryData.map(g => (
              <GalleryItem key={g.key}>
                <GalleryOverlay>
                  <GalleryText>{g.alt}</GalleryText>
                </GalleryOverlay>
                <img src={g.src} alt={g.alt} loading="lazy" />
              </GalleryItem>
            ))}
          </Gallery>
        </Section>

        <Section>
          <SectionTitle>Explore by Category</SectionTitle>
          <Categories>
            {categories.map(c => (
              <CategoryCard key={c.title} onClick={() => setCategory(c.title)}>
                <CategoryImageWrapper>
                  <CategoryImage src={c.image} alt={c.title} loading="lazy" />
                  <CategoryOverlay />
                </CategoryImageWrapper>
                <CategoryBody>
                  <CategoryIcon>{c.icon}</CategoryIcon>
                  <CategoryTitle>{c.title}</CategoryTitle>
                  <CategoryDesc>{c.desc}</CategoryDesc>
                </CategoryBody>
              </CategoryCard>
            ))}
          </Categories>
        </Section>

        <Section id="featured">
          <Title>Featured Sweets</Title>
          <FilterBar>
            <SearchBox>
              <SearchIcon>🔍</SearchIcon>
              <SearchInput
                type="text"
                placeholder="Search sweets..."
                value={query}
                onChange={(e) => setQuery(e.target.value)}
              />
            </SearchBox>
            <FilterSelect value={category} onChange={(e) => setCategory(e.target.value)}>
              <option value="">All Categories</option>
              <option value="Candy">🍬 Candy</option>
              <option value="Chocolate">🍫 Chocolate</option>
              <option value="Sugar">🍭 Sugar</option>
              <option value="Nougat">🍯 Nougat</option>
              <option value="Caramel">🍮 Caramel</option>
              <option value="Gummies">🐻 Gummies</option>
            </FilterSelect>
          </FilterBar>

          {state.error && <ErrorAlert>{state.error}</ErrorAlert>}
          {state.loading && <LoadingText>Loading delicious treats...</LoadingText>}
          
          <Grid>
            {filtered.map(s => (
              <SweetCard key={s._id}>
                <CardImage src={s.imageUrl} alt={s.name} loading="lazy" />
                <CardBadge>{s.category}</CardBadge>
                <CardBody>
                  <CardTitle>{s.name}</CardTitle>
                  <CardPrice>${s.price}</CardPrice>
                  <CardStock stock={s.stock}>
                    {s.stock > 10 ? '✓ In Stock' : s.stock > 0 ? `⚠ Only ${s.stock} left` : '✗ Out of Stock'}
                  </CardStock>
                  <CardButton onClick={() => add(s)} disabled={s.stock === 0}>
                    {s.stock > 0 ? 'Add to Cart' : 'Sold Out'}
                  </CardButton>
                </CardBody>
              </SweetCard>
            ))}
          </Grid>
        </Section>
      </ContentWrapper>
    </Wrapper>
  );
}

const Section = styled.section`
  margin: 80px 0;
`;

const SectionTitle = styled.h2`
  font-size: clamp(32px, 5vw, 42px);
  color: ${colors.text};
  margin-bottom: 48px;
  font-weight: 700;
  text-align: center;
  background: linear-gradient(135deg, ${colors.primary}, ${colors.secondary});
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
`;

const Hero = styled.section`
  position: relative;
  height: 80vh;
  min-height: 600px;
  overflow: hidden;
  background: linear-gradient(135deg, #fef5f9 0%, #f0e8ff 50%, #e8f4fa 100%);
`;

const Parallax = styled.div`
  position: absolute;
  inset: 0;
  background: 
    radial-gradient(circle at 20% 30%, rgba(255, 197, 217, 0.15), transparent 40%),
    radial-gradient(circle at 80% 70%, rgba(184, 166, 217, 0.15), transparent 40%),
    radial-gradient(circle at 50% 50%, rgba(168, 216, 234, 0.1), transparent 50%);
`;

const HeroInner = styled.div`
  position: relative;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 24px;
  z-index: 1;
`;

const HeroContent = styled.div`
  text-align: center;
  max-width: 700px;
  z-index: 3;
`;

const HeroTitle = styled.h1`
  font-size: clamp(42px, 6vw, 64px);
  color: ${colors.text};
  margin: 0 0 20px 0;
  font-weight: 800;
  line-height: 1.2;
  background: linear-gradient(135deg, ${colors.primary}, ${colors.secondary});
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  text-shadow: 0 2px 12px rgba(0,0,0,0.15);
`;

const HeroSubtitle = styled.p`
  font-size: clamp(16px, 2vw, 20px);
  color: ${colors.textLight};
  margin: 0 0 40px 0;
  line-height: 1.6;
  text-shadow: 0 2px 12px rgba(0,0,0,0.12);
`;

const HeroButton = styled.button`
  padding: 16px 40px;
  border: none;
  border-radius: 50px;
  background: linear-gradient(135deg, ${colors.primary}, ${colors.secondary});
  color: white;
  font-size: 18px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 8px 24px rgba(255, 197, 217, 0.4);
  
  &:hover {
    transform: translateY(-3px);
    box-shadow: 0 12px 32px rgba(255, 197, 217, 0.5);
  }
  
  &:active {
    transform: translateY(-1px);
  }
`;

const HeroBubbles = styled.div`
  pointer-events: none;
  position: absolute;
  inset: 0;
  z-index: 1;
`;

const floatAnim = keyframes`
  0%, 100% { transform: translate3d(0, 0, 0) scale(1); }
  50% { transform: translate3d(0, -24px, 0) scale(1.06); }
`;

const Bubble = styled.div`
  position: absolute;
  width: clamp(80px, 10vw, 120px);
  height: clamp(80px, 10vw, 120px);
  border-radius: 50%;
  animation: ${floatAnim} 5s ease-in-out infinite;
  will-change: transform;
  opacity: 0.85;
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
  overflow: hidden;
  img { width: 100%; height: 100%; object-fit: cover; display: block; }
`;

const BubbleInner = styled.div`
  width: 100%;
  height: 100%;
  border-radius: 50%;
  background: ${props => props.color};
  box-shadow: inset 0 0 30px rgba(255, 255, 255, 0.5), 0 10px 30px rgba(0, 0, 0, 0.1);
`;

const Gallery = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 20px;
`;

const GalleryItem = styled.div`
  position: relative;
  overflow: hidden;
  border-radius: 20px;
  box-shadow: 0 10px 30px ${colors.shadow};
  aspect-ratio: 4/3;
  cursor: pointer;
  
  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
    transition: transform 0.4s ease;
  }
  
  &:hover img {
    transform: scale(1.1);
  }
  
  &:hover > div {
    opacity: 1;
  }
`;

const GalleryOverlay = styled.div`
  position: absolute;
  inset: 0;
  background: linear-gradient(to top, rgba(0, 0, 0, 0.45), transparent);
  display: flex;
  align-items: flex-end;
  padding: 20px;
  opacity: 0;
  transition: opacity 0.3s ease;
  z-index: 1;
`;

const GalleryText = styled.p`
  color: white;
  font-size: 16px;
  font-weight: 600;
  margin: 0;
  text-shadow: 0 2px 8px rgba(0,0,0,0.4);
`;

const Categories = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 32px;
`;

const CategoryCard = styled.div`
  border-radius: 24px;
  background: ${colors.cardBg};
  box-shadow: 0 8px 24px ${colors.shadow};
  overflow: hidden;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:hover {
    transform: translateY(-8px);
    box-shadow: 0 16px 40px rgba(149, 157, 165, 0.25);
  }
`;

const CategoryImageWrapper = styled.div`
  position: relative;
  height: 200px;
  overflow: hidden;
`;

const CategoryImage = styled.img`
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.4s ease;
  
  ${CategoryCard}:hover & {
    transform: scale(1.1);
  }
`;

const CategoryOverlay = styled.div`
  position: absolute;
  inset: 0;
  background: linear-gradient(to bottom, transparent, rgba(0, 0, 0, 0.1));
`;

const CategoryBody = styled.div`
  padding: 24px;
  text-align: center;
`;

const CategoryIcon = styled.div`
  font-size: 48px;
  margin-bottom: 12px;
`;

const CategoryTitle = styled.h3`
  margin: 0 0 8px 0;
  font-size: 24px;
  color: ${colors.text};
  font-weight: 600;
`;

const CategoryDesc = styled.p`
  margin: 0;
  color: ${colors.textLight};
  font-size: 15px;
  line-height: 1.5;
`;

const FilterBar = styled.div`
  display: flex;
  gap: 16px;
  margin: 32px 0;
  flex-wrap: wrap;
  justify-content: center;
`;

const SearchBox = styled.div`
  position: relative;
  flex: 1;
  min-width: 250px;
  max-width: 400px;
`;

const SearchIcon = styled.span`
  position: absolute;
  left: 16px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 18px;
`;

const SearchInput = styled.input`
  width: 100%;
  padding: 14px 16px 14px 48px;
  border: 2px solid ${colors.primary};
  border-radius: 50px;
  font-size: 16px;
  transition: all 0.3s ease;
  background: white;
  
  &:focus {
    outline: none;
    box-shadow: 0 4px 16px rgba(255, 197, 217, 0.3);
    border-color: ${colors.secondary};
  }
`;

const FilterSelect = styled.select`
  padding: 14px 20px;
  border: 2px solid ${colors.primary};
  border-radius: 50px;
  font-size: 16px;
  background: white;
  cursor: pointer;
  transition: all 0.3s ease;
  min-width: 200px;
  
  &:focus {
    outline: none;
    box-shadow: 0 4px 16px rgba(255, 197, 217, 0.3);
    border-color: ${colors.secondary};
  }
`;

const SweetCard = styled.div`
  border-radius: 20px;
  background: ${colors.cardBg};
  box-shadow: 0 8px 24px ${colors.shadow};
  overflow: hidden;
  transition: all 0.3s ease;
  position: relative;
  
  &:hover {
    transform: translateY(-8px);
    box-shadow: 0 16px 40px rgba(149, 157, 165, 0.25);
  }
`;

const CardImage = styled.img`
  width: 100%;
  height: 220px;
  object-fit: cover;
  display: block;
`;

const CardBadge = styled.div`
  position: absolute;
  top: 16px;
  right: 16px;
  padding: 6px 14px;
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  font-size: 12px;
  font-weight: 600;
  color: ${colors.text};
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
`;

const CardBody = styled.div`
  padding: 20px;
`;

const CardTitle = styled.h3`
  margin: 0 0 8px 0;
  font-size: 20px;
  color: ${colors.text};
  font-weight: 600;
`;

const CardPrice = styled.div`
  font-size: 24px;
  color: ${colors.secondary};
  font-weight: 700;
  margin-bottom: 8px;
`;

const CardStock = styled.div`
  font-size: 14px;
  color: ${props => props.stock > 10 ? '#4caf50' : props.stock > 0 ? '#ff9800' : '#f44336'};
  margin-bottom: 16px;
  font-weight: 500;
`;

const CardButton = styled.button`
  width: 100%;
  padding: 12px;
  border: none;
  border-radius: 12px;
  background: ${props => props.disabled ? '#e0e0e0' : `linear-gradient(135deg, ${colors.primary}, ${colors.secondary})`};
  color: ${props => props.disabled ? '#999' : 'white'};
  font-size: 16px;
  font-weight: 600;
  cursor: ${props => props.disabled ? 'not-allowed' : 'pointer'};
  transition: all 0.3s ease;
  
  &:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(255, 197, 217, 0.4);
  }
`;

const ErrorAlert = styled.div`
  padding: 16px 24px;
  border-radius: 12px;
  background: #ffebee;
  color: #c62828;
  text-align: center;
  margin: 24px 0;
  font-weight: 500;
`;

const LoadingText = styled.div`
  text-align: center;
  padding: 40px;
  font-size: 18px;
  color: ${colors.textLight};
`;

const categories = [
  { title: 'Candy', desc: 'Colorful treats with a delightful crunchy bite', image: '/candy.jpg', icon: '🍬' },
  { title: 'Chocolate', desc: 'Rich cocoa delicacies for true connoisseurs', image: '/chocolate.jpg', icon: '🍫' },
  { title: 'Sugar', desc: 'Sweet classics to savor every moment', image: '/suger.jpg', icon: '🍭' },
  { title: 'Nougat', desc: 'Honey and nuts in perfect harmony', image: '/nauagt.jpg', icon: '🍯' },
  { title: 'Caramel', desc: 'Buttery smooth goodness that melts in your mouth', image: '/caramel.jpg', icon: '🍮' },
  { title: 'Gummies', desc: 'Chewy fruity favorites loved by all ages', image: '/gummies.jpg', icon: '🐻' }
];

const heroBubbles = [
  { src: '/candy.jpg', left: '8%', top: '15%', delay: '0s' },
  { src: '/chocolate.jpg', left: '20%', top: '65%', delay: '0.8s' },
  { src: '/gummies.jpg', left: '75%', top: '20%', delay: '1.2s' },
  { src: '/caramel.jpg', left: '85%', top: '70%', delay: '1.8s' },
  { src: '/sweets.jpg', left: '50%', top: '40%', delay: '2.4s' }
];

// Top Navigation Components
const TopNavigation = styled.nav`
  position: sticky;
  top: 0;
  z-index: 1000;
  background: linear-gradient(135deg, 
    rgba(255, 245, 249, 0.95) 0%, 
    rgba(240, 232, 255, 0.95) 50%, 
    rgba(232, 244, 250, 0.95) 100%);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.6);
  box-shadow: 0 4px 24px rgba(149, 157, 165, 0.15);
  
  &::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: 
      radial-gradient(circle at 20% 30%, rgba(255, 197, 217, 0.1), transparent 40%),
      radial-gradient(circle at 80% 70%, rgba(184, 166, 217, 0.1), transparent 40%),
      radial-gradient(circle at 50% 50%, rgba(168, 216, 234, 0.08), transparent 50%);
    pointer-events: none;
  }
`;

const NavContainer = styled.div`
  max-width: 1400px;
  margin: 0 auto;
  padding: 16px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  position: relative;
  z-index: 1;
`;

const Logo = styled(Link)`
  display: flex;
  align-items: center;
  gap: 12px;
  text-decoration: none;
  color: ${colors.text};
  font-size: 24px;
  font-weight: 700;
  transition: all 0.3s ease;
  
  &:hover {
    transform: translateY(-2px);
  }
`;

const LogoIcon = styled.span`
  font-size: 32px;
  filter: drop-shadow(0 2px 4px rgba(0,0,0,0.1));
`;

const NavLinks = styled.div`
  display: flex;
  gap: 8px;
  align-items: center;
`;

const NavLink = styled(Link)`
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  border-radius: 50px;
  text-decoration: none;
  color: ${colors.text};
  font-weight: 500;
  background: ${props => props.$active ? 
    'linear-gradient(135deg, rgba(255, 197, 217, 0.2), rgba(184, 166, 217, 0.2))' : 
    'transparent'};
  border: 2px solid ${props => props.$active ? colors.primary : 'transparent'};
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
  
  &::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.4), transparent);
    transition: left 0.5s ease;
  }
  
  &:hover {
    background: linear-gradient(135deg, rgba(255, 197, 217, 0.15), rgba(184, 166, 217, 0.15));
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(255, 197, 217, 0.3);
    
    &::before {
      left: 100%;
    }
  }
  
  &:active {
    transform: translateY(0);
  }
`;

const CartLink = styled(NavLink)`
  position: relative;
  background: linear-gradient(135deg, ${colors.primary}, ${colors.secondary});
  color: white;
  border: none;
  
  &:hover {
    background: linear-gradient(135deg, ${colors.primary}, ${colors.secondary});
    box-shadow: 0 6px 20px rgba(255, 197, 217, 0.4);
  }
`;

const NavIcon = styled.span`
  font-size: 18px;
  filter: drop-shadow(0 1px 2px rgba(0,0,0,0.1));
`;

const CartBadge = styled.span`
  position: absolute;
  top: -4px;
  right: -4px;
  background: ${colors.accent};
  color: ${colors.text};
  font-size: 12px;
  font-weight: 700;
  padding: 2px 6px;
  border-radius: 10px;
  min-width: 18px;
  text-align: center;
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
  animation: pulse 2s infinite;
`;

const pulse = keyframes`
  0% { transform: scale(1); }
  50% { transform: scale(1.1); }
  100% { transform: scale(1); }
`;