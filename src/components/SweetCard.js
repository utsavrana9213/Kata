import styled from 'styled-components';

const Card = styled.div`
  background: #fff;
  border-radius: ${({ theme }) => theme.radii.md};
  box-shadow: ${({ theme }) => theme.shadow};
  overflow: hidden;
  display: flex;
  flex-direction: column;
`;

const Img = styled.img`
  width: 100%;
  height: 160px;
  object-fit: cover;
`;

const Body = styled.div`
  padding: 12px;
  display: grid;
  gap: 8px;
`;

const Price = styled.div`
  color: ${({ theme }) => theme.colors.primary};
  font-weight: 700;
`;

export default function SweetCard({ sweet, onAdd, onPurchase, onRestock, isAdmin }) {
  const img = sweet.imageUrl || `https://picsum.photos/seed/${encodeURIComponent(sweet.name)}-sweet/400/300`;
  const rating = sweet.rating || Math.round(Math.random() * 2 + 3);
  const canPurchase = sweet.quantity > 0;
  const handlePurchase = () => {
    if (canPurchase) onPurchase?.(sweet);
  };
  return (
    <Card aria-label={`Sweet ${sweet.name}`}>
      <Img src={img} alt={sweet.name} />
      <Body>
        <div>{sweet.name}</div>
        <Price>${sweet.price.toFixed(2)}</Price>
        <div aria-label="Rating">{'★'.repeat(rating)}{'☆'.repeat(5 - rating)}</div>
        <div aria-label="Quantity">In stock: {sweet.quantity}</div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={handlePurchase} disabled={!canPurchase}>
            {canPurchase ? 'Purchase' : 'Out of Stock'}
          </button>
          <button onClick={() => onAdd?.(sweet)}>Add to Cart</button>
          {isAdmin && (
            <button onClick={() => onRestock?.(sweet)}>Restock</button>
          )}
        </div>
      </Body>
    </Card>
  );
}