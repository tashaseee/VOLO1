// API на том же хосте/порте; UI — /panel/, эндпоинты — /admin/, /auth/, ...
export const API_URL = "";

export const mediaUrl = (path) => {
  if (!path) return "";
  if (path.startsWith("http")) return path;
  return path.startsWith("/") ? path : `/${path}`;
};

const getHeaders = (token) => ({
  Authorization: `Bearer ${token}`,
  "Content-Type": "application/json",
});

async function parseJsonResponse(response) {
  const text = await response.text();
  if (!text) return {};
  try {
    return JSON.parse(text);
  } catch {
    const preview = text.replace(/\s+/g, " ").slice(0, 120);
    throw new Error(
      preview.startsWith("<")
        ? "Сервер вернул HTML вместо JSON. Проверьте, что бэкенд запущен на порту 8080."
        : preview || "Некорректный ответ сервера",
    );
  }
}

export const apiLogin = async (email, password) => {
  const response = await fetch(`${API_URL}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
  const data = await parseJsonResponse(response);
  if (!response.ok) {
    throw new Error(
      typeof data.detail === "string"
        ? data.detail
        : Array.isArray(data.detail)
          ? data.detail.map((e) => e.msg).join(", ")
          : "Ошибка входа",
    );
  }
  return data;
};

async function apiGet(url, token) {
  const response = await fetch(url, { headers: getHeaders(token) });
  if (response.status === 401) {
    localStorage.removeItem('token');
    window.location.href = '/panel/login';
    throw new Error("Сессия истекла. Пожалуйста, войдите снова.");
  }
  const data = await parseJsonResponse(response);
  if (!response.ok) {
    throw new Error(data.detail || "Ошибка запроса");
  }
  return data;
}

async function apiMutate(url, token, method = "POST") {
  const response = await fetch(url, { method, headers: getHeaders(token) });
  if (response.status === 401) {
    localStorage.removeItem('token');
    window.location.href = '/panel/login';
    throw new Error("Сессия истекла. Пожалуйста, войдите снова.");
  }
  const data = await parseJsonResponse(response);
  if (!response.ok) {
    throw new Error(data.detail || "Ошибка запроса");
  }
  return data;
}

export const fetchStats = (token) => apiGet(`${API_URL}/admin/stats`, token);

export const fetchPendingOrgs = (token) =>
  apiGet(`${API_URL}/admin/pending-organizations`, token);

export const approveOrg = (token, userId) =>
  apiMutate(`${API_URL}/admin/approve-organization/${userId}`, token, "POST");

export const fetchUsers = async (token, role = null) => {
  let url = `${API_URL}/admin/users`;
  if (role) url += `?role=${role}`;
  return apiGet(url, token);
};

export const fetchUserDetail = (token, userId) =>
  apiGet(`${API_URL}/admin/users/${userId}`, token);

export const toggleUserActive = (token, userId) =>
  apiMutate(`${API_URL}/admin/users/${userId}/toggle-active`, token, "POST");

export const fetchEvents = (token) => apiGet(`${API_URL}/admin/events`, token);

export const fetchEventDetail = (token, eventId) =>
  apiGet(`${API_URL}/admin/events/${eventId}`, token);

export const toggleEventActive = (token, eventId) =>
  apiMutate(`${API_URL}/admin/events/${eventId}/toggle-active`, token, "POST");

export const deleteUser = (token, userId) =>
  apiMutate(`${API_URL}/admin/users/${userId}`, token, "DELETE");

export const deleteEvent = (token, eventId) =>
  apiMutate(`${API_URL}/admin/events/${eventId}`, token, "DELETE");

export const fetchActivity = (token) => apiGet(`${API_URL}/admin/activity`, token);

export const fetchReports = (token) => apiGet(`${API_URL}/admin/reports`, token);

export const fetchSupportRequests = (token) => apiGet(`${API_URL}/support/all`, token);

export const replyToSupportRequest = async (token, requestId, replyText) => {
  const body = new URLSearchParams();
  body.append('reply', replyText);

  const response = await fetch(`${API_URL}/support/${requestId}/reply`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: body.toString(),
  });

  if (response.status === 401) {
    localStorage.removeItem('token');
    window.location.href = '/panel/login';
    throw new Error("Сессия истекла. Пожалуйста, войдите снова.");
  }
  const data = await parseJsonResponse(response);
  if (!response.ok) {
    throw new Error(data.detail || "Ошибка запроса");
  }
  return data;
};
