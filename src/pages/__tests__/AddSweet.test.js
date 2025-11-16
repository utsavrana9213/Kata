import { render, screen, fireEvent } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { ThemeProvider } from 'styled-components';
import { theme } from '../../theme';
import { AuthProvider } from '../../context/AuthContext';
import { CartProvider } from '../../context/CartContext';
import AddSweet from '../../pages/AddSweet';

test('validates required fields before submit', () => {
  render(
    <BrowserRouter>
      <ThemeProvider theme={theme}>
        <AuthProvider>
          <CartProvider>
            <AddSweet />
          </CartProvider>
        </AuthProvider>
      </ThemeProvider>
    </BrowserRouter>
  );
  const form = screen.getByRole('form', { name: /Add sweet form/i });
  fireEvent.submit(form);
  expect(screen.getByText(/Name is required/i)).toBeInTheDocument();
  expect(screen.getByText(/Valid price required/i)).toBeInTheDocument();
  expect(screen.getByText(/Valid quantity required/i)).toBeInTheDocument();
});