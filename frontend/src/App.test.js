import { render, screen } from '@testing-library/react';
import App from './App';

test('renders login form', () => {
  render(<App />);
  const loginElement = screen.getByText(/Login to eno Chat/i);
  expect(loginElement).toBeInTheDocument();
});
