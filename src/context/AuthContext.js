import { createContext, useContext, useEffect, useReducer } from 'react';

const AuthContext = createContext();

const initial = { user: null, token: null, loading: false, error: null, remember: true };

function reducer(state, action) {
  switch (action.type) {
    case 'start':
      return { ...state, loading: true, error: null };
    case 'error':
      return { ...state, loading: false, error: action.payload };
    case 'login':
      return { ...state, loading: false, token: action.payload.token, user: action.payload.user };
    case 'logout':
      return { ...initial, remember: state.remember };
    case 'remember':
      return { ...state, remember: action.payload };
    default:
      return state;
  }
}

export function AuthProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, initial);

  useEffect(() => {
    const saved = localStorage.getItem('kata_auth');
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        dispatch({ type: 'login', payload: parsed });
      } catch {}
    }
  }, []);

  useEffect(() => {
    if (state.remember && state.token) {
      localStorage.setItem('kata_auth', JSON.stringify({ token: state.token, user: state.user }));
    }
  }, [state.remember, state.token, state.user]);

  async function register({ email, password }) {
    dispatch({ type: 'start' });
    try {
      const { client } = await import('../api/client');
      await client.post('/auth/register', { email, password });
      return true;
    } catch (e) {
      dispatch({ type: 'error', payload: 'Registration failed' });
      return false;
    }
  }

  async function login({ email, password, remember }) {
    dispatch({ type: 'start' });
    try {
      const { client } = await import('../api/client');
      const res = await client.post('/auth/login', { email, password });
      dispatch({ type: 'remember', payload: !!remember });
      const user = parseJwt(res.data.token);
      dispatch({ type: 'login', payload: { token: res.data.token, user: { id: user.sub, role: user.role, email } } });
      return true;
    } catch (e) {
      dispatch({ type: 'error', payload: 'Login failed' });
      return false;
    }
  }

  function logout() {
    localStorage.removeItem('kata_auth');
    dispatch({ type: 'logout' });
  }

  function parseJwt(token) {
    try { return JSON.parse(atob(token.split('.')[1])); } catch { return {}; }
  }

  return (
    <AuthContext.Provider value={{ state, register, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}