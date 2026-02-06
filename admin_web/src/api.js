const API_URL = "http://10.202.7.234:8080";

const getHeaders = (token) => ({
  'Authorization': `Bearer ${token}`,
  'Content-Type': 'application/json'
});

export const apiLogin = async (email, password) => {
  const response = await fetch(`${API_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.detail || 'Login failed');
  }
  return response.json();
};

export const fetchStats = async (token) => {
  const response = await fetch(`${API_URL}/admin/stats`, {
    headers: getHeaders(token)
  });
  if (!response.ok) throw new Error('Failed to fetch stats');
  return response.json();
};

export const fetchPendingOrgs = async (token) => {
  const response = await fetch(`${API_URL}/admin/pending-organizations`, {
    headers: getHeaders(token)
  });
  if (!response.ok) throw new Error('Failed to fetch pending organizations');
  return response.json();
};

export const approveOrg = async (token, userId) => {
  const response = await fetch(`${API_URL}/admin/approve-organization/${userId}`, {
    method: 'POST',
    headers: getHeaders(token)
  });
  if (!response.ok) throw new Error('Failed to approve');
  return response.json();
};

export const fetchUsers = async (token, role = null) => {
  let url = `${API_URL}/admin/users`;
  if (role) url += `?role=${role}`;
  const response = await fetch(url, { headers: getHeaders(token) });
  if (!response.ok) throw new Error('Failed to fetch users');
  return response.json();
};

export const fetchEvents = async (token) => {
  const response = await fetch(`${API_URL}/admin/events`, { headers: getHeaders(token) });
  if (!response.ok) throw new Error('Failed to fetch events');
  return response.json();
};

export const deleteUser = async (token, userId) => {
  const response = await fetch(`${API_URL}/admin/users/${userId}`, {
    method: 'DELETE',
    headers: getHeaders(token)
  });
  if (!response.ok) throw new Error('Failed to delete user');
  return response.json();
};

export const deleteEvent = async (token, eventId) => {
  const response = await fetch(`${API_URL}/admin/events/${eventId}`, {
    method: 'DELETE',
    headers: getHeaders(token)
  });
  if (!response.ok) throw new Error('Failed to delete event');
  return response.json();
};
