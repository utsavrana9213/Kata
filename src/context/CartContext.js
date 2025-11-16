import { createContext, useContext, useReducer } from 'react';

const CartContext = createContext();

function reducer(state, action) {
  switch (action.type) {
    case 'add': {
      const existing = state.items.find(i => i._id === action.item._id);
      if (existing) {
        return { ...state, items: state.items.map(i => i._id === action.item._id ? { ...i, qty: i.qty + 1 } : i) };
      }
      return { ...state, items: [...state.items, { ...action.item, qty: 1 }] };
    }
    case 'remove':
      return { ...state, items: state.items.filter(i => i._id !== action.id) };
    case 'clear':
      return { items: [] };
    default:
      return state;
  }
}

export function CartProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, { items: [] });
  function add(item) { dispatch({ type: 'add', item }); }
  function remove(id) { dispatch({ type: 'remove', id }); }
  function clear() { dispatch({ type: 'clear' }); }
  return <CartContext.Provider value={{ state, add, remove, clear }}>{children}</CartContext.Provider>;
}

export function useCart() { return useContext(CartContext); }