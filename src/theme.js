export const theme = {
  colors: {
    primary: '#ff6b6b',
    secondary: '#ffd93d',
    bg: '#fff7f0',
    text: '#2b2b2b',
    muted: '#9a9a9a',
    success: '#2ecc71',
    danger: '#e74c3c'
  },
  spacing: (n) => `${n * 8}px`,
  radii: { sm: '6px', md: '10px', lg: '16px' },
  shadow: '0 8px 24px rgba(0,0,0,0.1)',
  breakpoints: { sm: '480px', md: '768px', lg: '1024px' }
};