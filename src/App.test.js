import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { AppProvider } from './context/AppContext';
import { AuthProvider } from './context/AuthContext';
import { ThemeProvider } from 'styled-components';
import { theme } from './theme';
import App from './App';

test('renders Featured Sweets section', async () => {
  jest.spyOn(console, 'warn').mockImplementation(() => {});
  render(
    <MemoryRouter initialEntries={["/"]}>
      <ThemeProvider theme={theme}>
        <AuthProvider>
          <AppProvider>
            <App />
          </AppProvider>
        </AuthProvider>
      </ThemeProvider>
    </MemoryRouter>
  );
  expect(await screen.findByText(/Loading/i)).toBeInTheDocument();
  expect(await screen.findByText(/Featured Sweets/i)).toBeInTheDocument();
});
