import React, { useEffect, useState } from 'react';
import { fetchUsers, deleteUser, fetchUserDetail, toggleUserActive } from '../api';
import {
    Users as UsersIcon,
    Search,
    Trash2,
    Mail,
    Shield,
    User,
    Calendar,
    MoreVertical,
    Filter,
    Ban,
    ShieldCheck,
    X,
    Phone,
    MapPin,
    Clock,
    BookOpen,
    Award,
    Circle
} from 'lucide-react';

export default function UsersPage({ token }) {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [roleFilter, setRoleFilter] = useState('');
    const [selectedUser, setSelectedUser] = useState(null);
    const [detailLoading, setDetailLoading] = useState(false);

    useEffect(() => {
        loadData();
    }, [roleFilter]);

    const loadData = async () => {
        setLoading(true);
        try {
            const data = await fetchUsers(token, roleFilter);
            setUsers(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Вы уверены, что хотите полностью удалить этого пользователя? Это действие необратимо.')) return;
        try {
            await deleteUser(token, id);
            setUsers(users.filter(u => u.id !== id));
            if (selectedUser?.id === id) setSelectedUser(null);
        } catch (e) {
            alert(e.message);
        }
    };

    const handleToggleActive = async (id) => {
        try {
            const result = await toggleUserActive(token, id);
            setUsers(users.map(u => u.id === id ? { ...u, is_active: result.is_active } : u));
            if (selectedUser?.id === id) setSelectedUser({ ...selectedUser, is_active: result.is_active });
        } catch (e) {
            alert(e.message);
        }
    };

    const handleViewDetail = async (userId) => {
        setDetailLoading(true);
        try {
            const data = await fetchUserDetail(token, userId);
            setSelectedUser(data);
        } catch (e) {
            alert('Ошибка при загрузке данных: ' + e.message);
        } finally {
            setDetailLoading(false);
        }
    };

    const filteredUsers = users.filter(u =>
        u.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.name?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const API_URL = "http://10.202.8.194:8080"; // Needs to be consistent with api.js

    const getAvatarUrl = (url) => {
        if (!url) return null;
        if (url.startsWith('http')) return url;
        return `${API_URL}${url}`;
    };

    return (
        <div className="animate-slide-in">
            <header style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
                <div>
                    <h1>Пользователи</h1>
                    <p className="page-description">Управление волонтерами и организаторами ({users.length})</p>
                </div>

                <div style={{ display: 'flex', gap: '1rem' }}>
                    <div style={{ position: 'relative' }}>
                        <Search size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
                        <input
                            type="text"
                            placeholder="Поиск по имени или email..."
                            className="search-input"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            style={{
                                padding: '0.625rem 1rem 0.625rem 2.5rem',
                                border: '1px solid var(--border)',
                                borderRadius: 'var(--radius)',
                                width: '280px',
                                outline: 'none'
                            }}
                        />
                    </div>
                    <select
                        value={roleFilter}
                        onChange={(e) => setRoleFilter(e.target.value)}
                        style={{
                            padding: '0.625rem 1rem',
                            border: '1px solid var(--border)',
                            borderRadius: 'var(--radius)',
                            background: 'white',
                            outline: 'none',
                            fontWeight: '500'
                        }}
                    >
                        <option value="">Все роли</option>
                        <option value="volunteer">Волонтеры</option>
                        <option value="organizer">Организаторы</option>
                    </select>
                </div>
            </header>

            <div className="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Пользователь</th>
                            <th>Роль</th>
                            <th>Статус</th>
                            <th>Регистрация</th>
                            <th style={{ textAlign: 'right' }}>Действия</th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan="5" style={{ textAlign: 'center', padding: '3rem' }}>Загрузка...</td></tr>
                        ) : filteredUsers.length === 0 ? (
                            <tr><td colSpan="5" style={{ textAlign: 'center', padding: '3rem' }}>Пользователи не найдены.</td></tr>
                        ) : filteredUsers.map((user) => (
                            <tr key={user.id} onClick={() => handleViewDetail(user.id)} style={{ cursor: 'pointer' }}>
                                <td>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                        <div style={{
                                            width: '40px', height: '40px', borderRadius: '12px',
                                            overflow: 'hidden',
                                            background: user.role === 'organizer' ? '#DBEAFE' : '#F3E8FF',
                                            color: user.role === 'organizer' ? '#3B82F6' : '#983296',
                                            display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold'
                                        }}>
                                            {user.avatar_url ? (
                                                <img src={getAvatarUrl(user.avatar_url)} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                            ) : (
                                                (user.name || "User")[0].toUpperCase()
                                            )}
                                        </div>
                                        <div>
                                            <p style={{ fontWeight: '600', fontSize: '0.9375rem' }}>{user.name}</p>
                                            <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>{user.email}</p>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <span className={`badge ${user.role === 'organizer' ? 'badge-warning' : 'badge-success'}`}>
                                        {user.role === 'organizer' ? 'Организатор' : 'Волонтер'}
                                    </span>
                                </td>
                                <td>
                                    <span className={`badge ${user.is_active ? 'badge-success' : 'badge-error'}`} style={{ display: 'flex', alignItems: 'center', gap: '4px', width: 'fit-content' }}>
                                        <Circle size={8} fill="currentColor" />
                                        {user.is_active ? 'Активен' : 'Заблокирован'}
                                    </span>
                                </td>
                                <td>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>
                                        <Clock size={14} />
                                        {new Date(user.created_at).toLocaleDateString()}
                                    </div>
                                </td>
                                <td style={{ textAlign: 'right' }} onClick={e => e.stopPropagation()}>
                                    <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'flex-end' }}>
                                        <button
                                            onClick={() => handleToggleActive(user.id)}
                                            className={`btn ${user.is_active ? 'btn-outline' : 'btn-primary'}`}
                                            style={{ padding: '0.5rem', color: user.is_active ? 'var(--error)' : 'white', borderColor: user.is_active ? 'var(--error)' : 'var(--primary)' }}
                                            title={user.is_active ? "Заблокировать" : "Разблокировать"}
                                        >
                                            <Ban size={16} />
                                        </button>
                                        <button
                                            onClick={() => handleDelete(user.id)}
                                            className="btn btn-danger-outline"
                                            style={{ padding: '0.5rem' }}
                                            title="Удалить"
                                        >
                                            <Trash2 size={16} />
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {/* User Detail Modal */}
            {selectedUser && (
                <div className="modal-overlay" onClick={() => setSelectedUser(null)}>
                    <div className="modal-content animate-slide-in" onClick={e => e.stopPropagation()}>
                        <button className="close-btn" onClick={() => setSelectedUser(null)}>
                            <X size={20} />
                        </button>

                        <div className="modal-header">
                            <div className="modal-avatar">
                                {selectedUser.avatar_url ? (
                                    <img src={getAvatarUrl(selectedUser.avatar_url)} alt="" />
                                ) : (
                                    (selectedUser.name || "User")[0].toUpperCase()
                                )}
                            </div>
                            <div className="modal-title-area">
                                <h2>{selectedUser.name}</h2>
                                <p>{selectedUser.role === 'organizer' ? '🏢 Организация' : '👤 Волонтер'} • ID: {selectedUser.id}</p>
                            </div>
                            <div className="modal-actions">
                                <button
                                    className={`btn ${selectedUser.is_active ? 'btn-danger-outline' : 'btn-primary'}`}
                                    onClick={() => handleToggleActive(selectedUser.id)}
                                >
                                    {selectedUser.is_active ? <Ban size={16} /> : <ShieldCheck size={16} />}
                                    {selectedUser.is_active ? 'Заблокировать' : 'Разблокировать'}
                                </button>
                            </div>
                        </div>

                        <div className="modal-body">
                            <div className="info-grid">
                                <div className="info-section">
                                    <h3><User size={16} /> Личные данные</h3>
                                    <div className="info-item">
                                        <Mail size={14} />
                                        <span>Email: <strong>{selectedUser.email}</strong></span>
                                    </div>
                                    <div className="info-item">
                                        <Phone size={14} />
                                        <span>Тел: <strong>{selectedUser.phone || 'Не указан'}</strong></span>
                                    </div>
                                    <div className="info-item">
                                        <MapPin size={14} />
                                        <span>Город: <strong>{selectedUser.city || 'Не указан'}</strong></span>
                                    </div>
                                </div>

                                {selectedUser.role === 'volunteer' ? (
                                    <div className="info-section">
                                        <h3><Award size={16} /> Активность</h3>
                                        <div className="stats-mini-grid">
                                            <div className="stat-mini">
                                                <p className="label">Часов</p>
                                                <p className="value">{selectedUser.volo_hours || 0}</p>
                                            </div>
                                            <div className="stat-mini">
                                                <p className="label">Ивентов</p>
                                                <p className="value">{selectedUser.events_done || 0}</p>
                                            </div>
                                            <div className="stat-mini">
                                                <p className="label">Эко</p>
                                                <p className="value">{selectedUser.eco_score || 0}</p>
                                            </div>
                                        </div>
                                    </div>
                                ) : (
                                    <div className="info-section">
                                        <h3><Building2 size={16} /> Орг. данные</h3>
                                        <div className="info-item">
                                            <span>БИН: <strong>{selectedUser.bin}</strong></span>
                                        </div>
                                        <div className="info-item">
                                            <span>Сайт: <strong>{selectedUser.website || '—'}</strong></span>
                                        </div>
                                    </div>
                                )}
                            </div>

                            <div className="detail-tags-section">
                                <h3><BookOpen size={16} /> Навыки и интересы</h3>
                                <div className="tags-container">
                                    {selectedUser.skills?.map(s => <span key={s} className="tag skill-tag">{s}</span>)}
                                    {selectedUser.interests?.map(i => <span key={i} className="tag interest-tag">{i}</span>)}
                                    {(!selectedUser.skills?.length && !selectedUser.interests?.length) && <p className="empty-text">Не указаны</p>}
                                </div>
                            </div>

                            <div className="description-section">
                                <h3><Clock size={16} /> О себе / Описание</h3>
                                <p className="description-text">
                                    {selectedUser.experience || selectedUser.description || 'Информация отсутствует.'}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            <style jsx="true">{`
                .modal-overlay {
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: rgba(15, 23, 42, 0.6);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    z-index: 1000;
                    backdrop-filter: blur(4px);
                }

                .modal-content {
                    background: white;
                    width: 100%;
                    max-width: 700px;
                    border-radius: var(--radius-lg);
                    box-shadow: var(--shadow-lg);
                    position: relative;
                    max-height: 90vh;
                    overflow-y: auto;
                }

                .close-btn {
                    position: absolute;
                    top: 1.5rem;
                    right: 1.5rem;
                    background: #f1f5f9;
                    border: none;
                    width: 36px;
                    height: 36px;
                    border-radius: 50%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    cursor: pointer;
                    color: var(--text-secondary);
                    transition: all 0.2s;
                }

                .close-btn:hover {
                    background: var(--error-bg);
                    color: var(--error);
                }

                .modal-header {
                    padding: 2.5rem;
                    border-bottom: 1px solid var(--border);
                    display: flex;
                    align-items: center;
                    gap: 1.5rem;
                }

                .modal-avatar {
                    width: 80px;
                    height: 80px;
                    border-radius: 20px;
                    background: var(--primary-light);
                    color: var(--primary);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 2rem;
                    font-weight: 700;
                    overflow: hidden;
                }

                .modal-avatar img {
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                }

                .modal-title-area h2 {
                    margin: 0;
                    font-size: 1.5rem;
                }

                .modal-title-area p {
                    margin: 0.25rem 0 0;
                    color: var(--text-secondary);
                    font-size: 0.875rem;
                }

                .modal-actions {
                    margin-left: auto;
                }

                .modal-body {
                    padding: 2.5rem;
                }

                .info-grid {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 2.5rem;
                    margin-bottom: 2rem;
                }

                .info-section h3 {
                    font-size: 0.875rem;
                    text-transform: uppercase;
                    color: var(--text-muted);
                    letter-spacing: 0.05em;
                    display: flex;
                    align-items: center;
                    gap: 0.5rem;
                    margin-bottom: 1.25rem;
                }

                .info-item {
                    display: flex;
                    align-items: center;
                    gap: 0.75rem;
                    margin-bottom: 0.75rem;
                    font-size: 0.9375rem;
                }

                .stats-mini-grid {
                    display: grid;
                    grid-template-columns: repeat(3, 1fr);
                    gap: 0.75rem;
                }

                .stat-mini {
                    background: #f8fafc;
                    padding: 0.75rem;
                    border-radius: var(--radius);
                    text-align: center;
                    border: 1px solid var(--border);
                }

                .stat-mini .label {
                    font-size: 0.625rem;
                    color: var(--text-muted);
                    margin: 0;
                }

                .stat-mini .value {
                    font-size: 1.125rem;
                    font-weight: 700;
                    color: var(--primary);
                    margin: 0.125rem 0 0;
                }

                .detail-tags-section, .description-section {
                    margin-top: 2rem;
                    padding-top: 2rem;
                    border-top: 1px solid var(--border);
                }

                .detail-tags-section h3, .description-section h3 {
                    font-size: 0.875rem;
                    color: var(--text-muted);
                    display: flex;
                    align-items: center;
                    gap: 0.5rem;
                    margin-bottom: 1rem;
                }

                .tags-container {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 0.5rem;
                }

                .tag {
                    padding: 0.375rem 0.75rem;
                    border-radius: 6px;
                    font-size: 0.75rem;
                    font-weight: 600;
                }

                .skill-tag { background: #E0F2FE; color: #0369A1; }
                .interest-tag { background: #F3E8FF; color: #983296; }

                .description-text {
                    font-size: 0.9375rem;
                    color: var(--text-secondary);
                    line-height: 1.6;
                }

                .empty-text {
                    color: var(--text-muted);
                    font-style: italic;
                    font-size: 0.875rem;
                }
            `}</style>
        </div>
    );
}
