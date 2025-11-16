import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { AppProvider } from './context/AppContext';
import App from './App';

test('renders Home title', async () => {
  render(
    <BrowserRouter>
      <AppProvider>
        <App />
      </AppProvider>
    </BrowserRouter>
  );
  expect(await screen.findByText(/Home/i)).toBeInTheDocument();
});
