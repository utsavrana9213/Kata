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

export default function SweetCard({ sweet, onAdd }) {
  const img = `https://picsum.photos/seed/${encodeURIComponent(sweet.name)}-sweet/400/300`;
  const rating = sweet.rating || Math.round(Math.random() * 2 + 3);
  return (
    <Card aria-label={`Sweet ${sweet.name}`}>
      <Img src={img} alt={sweet.name} />
      <Body>
        <div>{sweet.name}</div>
        <Price>${sweet.price.toFixed(2)}</Price>
        <div aria-label="Rating">{'★'.repeat(rating)}{'☆'.repeat(5 - rating)}</div>
        <button onClick={() => onAdd?.(sweet)}>Add to Cart</button>
      </Body>
    </Card>
  );
}