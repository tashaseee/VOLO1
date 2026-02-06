import React, { useEffect, useState } from 'react';
import { fetchUsers, deleteUser } from '../api';
import { Trash2, Search, User, ShieldCheck } from 'lucide-react';

export default function UsersPage({ token }) {
    const [users, setUsers] = useState([]);
    const [filteredUsers, setFilteredUsers] = useState([]);
    const [search, setSearch] = useState('');
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadData();
    }, []);

    useEffect(() => {
        setFilteredUsers(
            users.filter(u =>
                u.email.toLowerCase().includes(search.toLowerCase()) ||
                u.name.toLowerCase().includes(search.toLowerCase())
            )
        );
    }, [search, users]);

    const loadData = async () => {
        setLoading(true);
        try {
            const data = await fetchUsers(token);
            setUsers(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id) => {
        if (!confirm('Вы уверены, что хотите удалить этого пользователя? Это действие необратимо.')) return;
        try {
            await deleteUser(token, id);
            setUsers(prev => prev.filter(u => u.id !== id));
        } catch (e) {
            alert('Ошибка удаления: ' + e.message);
        }
    };

    return (
        <div className="animate-fade-in">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <div>
                    <h1>Пользователи</h1>
                    <p>Управление волонтерами и организаторами</p>
                </div>
                <div style={{ position: 'relative' }}>
                    <Search size={20} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#9CA3AF' }} />
                    <input
                        type="text"
                        placeholder="Поиск..."
                        value={search}
                        onChange={e => setSearch(e.target.value)}
                        style={{ paddingLeft: '2.5rem', width: '300px' }}
                    />
                </div>
            </div>

            <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead style={{ background: '#F9FAFB', borderBottom: '1px solid #E5E7EB' }}>
                        <tr>
                            <th style={{ padding: '1rem', textAlign: 'left', fontSize: '0.85rem', color: '#6B7280', textTransform: 'uppercase' }}>Пользователь</th>
                            <th style={{ padding: '1rem', textAlign: 'left', fontSize: '0.85rem', color: '#6B7280', textTransform: 'uppercase' }}>Роль</th>
                            <th style={{ padding: '1rem', textAlign: 'left', fontSize: '0.85rem', color: '#6B7280', textTransform: 'uppercase' }}>Статус</th>
                            <th style={{ padding: '1rem', textAlign: 'left', fontSize: '0.85rem', color: '#6B7280', textTransform: 'uppercase' }}>Дата регистрации</th>
                            <th style={{ padding: '1rem', textAlign: 'right', fontSize: '0.85rem', color: '#6B7280', textTransform: 'uppercase' }}>Действия</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredUsers.map(user => (
                            <tr key={user.id} style={{ borderBottom: '1px solid #F3F4F6' }}>
                                <td style={{ padding: '1rem' }}>
                                    <div style={{ fontWeight: 500 }}>{user.name}</div>
                                    <div style={{ fontSize: '0.85rem', color: '#6B7280' }}>{user.email}</div>
                                </td>
                                <td style={{ padding: '1rem' }}>
                                    {user.role === 'admin' && <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', background: '#FEF3C7', color: '#D97706', padding: '2px 8px', borderRadius: '100px', fontSize: '0.75rem', fontWeight: 600 }}><ShieldCheck size={12} /> Админ</span>}
                                    {user.role === 'organizer' && <span style={{ background: '#DBEAFE', color: '#2563EB', padding: '2px 8px', borderRadius: '100px', fontSize: '0.75rem', fontWeight: 600 }}>Организация</span>}
                                    {user.role === 'volunteer' && <span style={{ background: '#F3E8FF', color: '#983296', padding: '2px 8px', borderRadius: '100px', fontSize: '0.75rem', fontWeight: 600 }}>Волонтер</span>}
                                </td>
                                <td style={{ padding: '1rem' }}>
                                    <span style={{
                                        color: user.is_verified ? '#059669' : '#DC2626',
                                        fontSize: '0.85rem',
                                        fontWeight: 500
                                    }}>
                                        {user.is_verified ? 'Подтвержден' : 'Не подтвержден'}
                                    </span>
                                </td>
                                <td style={{ padding: '1rem', color: '#6B7280', fontSize: '0.9rem' }}>
                                    {new Date(user.created_at).toLocaleDateString()}
                                </td>
                                <td style={{ padding: '1rem', textAlign: 'right' }}>
                                    {user.role !== 'admin' && (
                                        <button
                                            onClick={() => handleDelete(user.id)}
                                            style={{ padding: '6px', borderRadius: '4px', border: 'none', background: '#FEE2E2', color: '#EF4444', cursor: 'pointer' }}
                                            title="Удалить"
                                        >
                                            <Trash2 size={16} />
                                        </button>
                                    )}
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
