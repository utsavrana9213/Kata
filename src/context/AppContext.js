import { createContext, useContext, useReducer } from 'react';

const AppContext = createContext();

const initialState = { loading: false, error: null };

function reducer(state, action) {
  switch (action.type) {
    case 'loading:start':
      return { ...state, loading: true };
    case 'loading:end':
      return { ...state, loading: false };
    case 'error:set':
      return { ...state, error: action.payload };
    case 'error:clear':
      return { ...state, error: null };
    default:
      return state;
  }
}

export function AppProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, initialState);
  return <AppContext.Provider value={{ state, dispatch }}>{children}</AppContext.Provider>;
}

export function useApp() {
  return useContext(AppContext);
}