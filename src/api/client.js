import axios from 'axios';

const baseURL = process.env.REACT_APP_API_BASE_URL || '/api';

export const client = axios.create({ baseURL });

client.interceptors.response.use(
  (response) => response,
  (error) => Promise.reject(error)
);