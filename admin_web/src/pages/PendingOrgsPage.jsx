import React, { useEffect, useState } from 'react';
import { fetchPendingOrgs, approveOrg } from '../api';
import {
    Building2,
    MapPin,
    Hash,
    CheckCircle2,
    XCircle,
    ExternalLink,
    ShieldAlert,
    Search,
    Filter,
    Phone,
    Globe,
    Calendar,
    FileText
} from 'lucide-react';

const highlightMatch = (text, search) => {
    if (!search || !text) return text;
    const parts = text.split(new RegExp(`(${search})`, 'gi'));
    return (
        <span>
            {parts.map((part, i) => 
                part.toLowerCase() === search.toLowerCase() 
                    ? <mark key={i} style={{ backgroundColor: 'rgba(152, 50, 150, 0.2)', color: 'var(--primary-dark)', fontWeight: 'bold', padding: '0 2px', borderRadius: '4px' }}>{part}</mark>
                    : part
            )}
        </span>
    );
};

export default function PendingOrgsPage({ token }) {
    const [orgs, setOrgs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [processingId, setProcessingId] = useState(null);

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            const data = await fetchPendingOrgs(token);
            setOrgs(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    const handleApprove = async (userId) => {
        if (!window.confirm('Вы уверены, что хотите одобрить эту организацию?')) return;

        setProcessingId(userId);
        try {
            await approveOrg(token, userId);
            setOrgs(orgs.filter(o => o.id !== userId));
        } catch (e) {
            alert('Ошибка при одобрении: ' + e.message);
        } finally {
            setProcessingId(null);
        }
    };

    const filteredOrgs = orgs.filter(org =>
        org.org_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        org.bin?.includes(searchTerm)
    );

    if (loading) return <div className="animate-pulse flex-center" style={{ height: '400px' }}>Загрузка заявок...</div>;

    return (
        <div className="animate-slide-in">
            <header style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
                <div>
                    <h1>Заявки на верификацию</h1>
                    <p className="page-description">Ожидают проверки: {orgs.length} организаций</p>
                </div>

                <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                    <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
                        <Search size={18} style={{ position: 'absolute', left: '16px', color: 'var(--primary)' }} />
                        <input
                            type="text"
                            placeholder="Поиск по названию или БИН..."
                            className="search-input"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            style={{ 
                                paddingLeft: '3rem', 
                                paddingRight: '1rem',
                                width: '360px',
                                height: '48px',
                                borderRadius: '14px',
                                border: '2px solid var(--border)',
                                background: 'white',
                                boxShadow: 'var(--shadow-sm)',
                                fontSize: '0.95rem',
                                fontWeight: '600',
                                color: 'var(--text-primary)',
                                transition: 'all 0.3s'
                            }}
                        />
                    </div>
                </div>
            </header>

            {filteredOrgs.length === 0 ? (
                <div className="card" style={{ textAlign: 'center', padding: '5rem 2rem' }}>
                    <div style={{ background: 'var(--success-bg)', color: 'var(--success)', width: '64px', height: '64px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 1.5rem' }}>
                        <CheckCircle2 size={32} />
                    </div>
                    <h2>Все заявки обработаны</h2>
                    <p style={{ color: 'var(--text-secondary)' }}>Новых заявок на верификацию пока нет.</p>
                </div>
            ) : (
                <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '2rem' }}>
                    {filteredOrgs.map((org) => (
                        <div key={org.id} className="card org-card" style={{ padding: '2rem' }}>
                            <div className="org-card-header">
                                <div className="org-meta">
                                    <div className="org-icon" style={{ background: 'linear-gradient(135deg, var(--primary-light), white)', border: '1px solid rgba(152, 50, 150, 0.1)' }}>
                                        <Building2 size={26} />
                                    </div>
                                    <div>
                                        <h3 style={{ fontSize: '1.25rem', fontWeight: '800' }}>
                                            {highlightMatch(org.org_name, searchTerm) || 'Без названия'}
                                        </h3>
                                        <div className="org-badges">
                                            <span className="badge badge-warning" style={{ fontSize: '0.7rem' }}>На верификации</span>
                                            <span className="badge" style={{ background: '#f1f5f9', color: '#475569', fontSize: '0.7rem' }}>ID: {org.id}</span>
                                        </div>
                                    </div>
                                </div>
                                <div className="org-actions" style={{ gap: '0.85rem' }}>
                                    <button
                                        className="btn btn-primary"
                                        disabled={processingId === org.id}
                                        onClick={() => handleApprove(org.id)}
                                        style={{ height: '44px', fontSize: '0.875rem' }}
                                    >
                                        <CheckCircle2 size={16} />
                                        {processingId === org.id ? 'Одобрение...' : 'Одобрить профиль'}
                                    </button>
                                </div>
                            </div>

                            <div className="org-details-grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))' }}>
                                <div className="detail-item" style={{ 
                                    border: searchTerm && org.bin?.includes(searchTerm) ? '1.5px solid rgba(152, 50, 150, 0.4)' : '1.5px solid transparent',
                                    background: searchTerm && org.bin?.includes(searchTerm) ? 'var(--primary-light)' : 'transparent',
                                    padding: '8px 12px',
                                    borderRadius: '12px',
                                    transition: 'all 0.3s',
                                    display: 'flex',
                                    gap: '0.75rem',
                                    alignItems: 'flex-start'
                                }}>
                                    <Hash size={16} className="detail-icon" style={{ color: 'var(--primary)' }} />
                                    <div>
                                        <p className="label">БИН / ИИН</p>
                                        <p className="value" style={{ fontFamily: 'monospace', fontSize: '1.05rem', letterSpacing: '0.05em' }}>
                                            {highlightMatch(org.bin, searchTerm) || '—-'}
                                        </p>
                                    </div>
                                </div>
                                <div className="detail-item">
                                    <Phone size={16} className="detail-icon" style={{ color: 'var(--primary)' }} />
                                    <div>
                                        <p className="label">Контактный телефон</p>
                                        <p className="value">{org.phone && org.phone !== 'Не указано' ? org.phone : '—-'}</p>
                                    </div>
                                </div>
                                <div className="detail-item">
                                    <Globe size={16} className="detail-icon" style={{ color: 'var(--primary)' }} />
                                    <div>
                                        <p className="label">Официальный сайт</p>
                                        <p className="value">
                                            {org.website && org.website !== 'Не указано' ? (
                                                <a href={org.website.startsWith('http') ? org.website : `https://${org.website}`} target="_blank" rel="noopener noreferrer" style={{ color: 'var(--primary)', textDecoration: 'none', display: 'inline-flex', alignItems: 'center', gap: '4px', fontWeight: '700' }}>
                                                    {org.website.replace(/^https?:\/\/(www\.)?/, '')}
                                                    <ExternalLink size={12} />
                                                </a>
                                            ) : '—-'}
                                        </p>
                                    </div>
                                </div>
                                <div className="detail-item">
                                    <MapPin size={16} className="detail-icon" style={{ color: 'var(--primary)' }} />
                                    <div>
                                        <p className="label">Адрес офиса</p>
                                        <p className="value">{org.address && org.address !== 'Не указано' ? org.address : '—-'}</p>
                                    </div>
                                </div>
                                <div className="detail-item">
                                    <ExternalLink size={16} className="detail-icon" style={{ color: 'var(--primary)' }} />
                                    <div>
                                        <p className="label">Email владельца</p>
                                        <p className="value" style={{ wordBreak: 'break-all' }}>{org.email}</p>
                                    </div>
                                </div>
                                <div className="detail-item">
                                    <Calendar size={16} className="detail-icon" style={{ color: 'var(--primary)' }} />
                                    <div>
                                        <p className="label">Дата подачи заявки</p>
                                        <p className="value">
                                            {org.created_at ? new Date(org.created_at).toLocaleDateString('ru-RU', { day: 'numeric', month: 'long', year: 'numeric' }) : 'Недавно'}
                                        </p>
                                    </div>
                                </div>
                            </div>

                            {org.description && org.description !== 'Не указано' && (
                                <div style={{ marginTop: '1.5rem', background: '#F9FAF8', padding: '1.25rem', borderRadius: 'var(--radius)', borderLeft: '4px solid var(--primary)', boxShadow: 'inset 0 1px 3px rgba(0,0,0,0.01)' }}>
                                    <p style={{ fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--text-secondary)', marginBottom: '0.5rem', fontWeight: '700', display: 'flex', alignItems: 'center', gap: '6px' }}>
                                        <FileText size={14} style={{ color: 'var(--primary)' }} />
                                        Описание деятельности и миссия
                                    </p>
                                    <p style={{ fontSize: '0.9rem', color: 'var(--text-primary)', lineHeight: '1.6', fontWeight: '500' }}>{org.description}</p>
                                </div>
                            )}

                            <style jsx="true">{`
                                .org-card {
                                    transition: transform 0.2s;
                                }
                                .org-card:hover {
                                    transform: translateX(4px);
                                }
                                .org-card-header {
                                    display: flex;
                                    justify-content: space-between;
                                    align-items: flex-start;
                                    margin-bottom: 2rem;
                                }
                                .org-meta {
                                    display: flex;
                                    gap: 1.25rem;
                                    align-items: center;
                                }
                                .org-icon {
                                    width: 56px;
                                    height: 56px;
                                    background: var(--primary-light);
                                    color: var(--primary);
                                    border-radius: 14px;
                                    display: flex;
                                    align-items: center;
                                    justify-content: center;
                                }
                                .org-badges {
                                    display: flex;
                                    gap: 0.5rem;
                                    margin-top: 0.5rem;
                                }
                                .org-actions {
                                    display: flex;
                                    gap: 0.75rem;
                                }
                                .org-details-grid {
                                    display: grid;
                                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                                    gap: 2rem;
                                    padding-top: 1.5rem;
                                    border-top: 1px solid var(--border);
                                }
                                .detail-item {
                                    display: flex;
                                    gap: 0.75rem;
                                    align-items: flex-start;
                                }
                                .detail-icon {
                                    color: var(--text-muted);
                                    margin-top: 0.25rem;
                                }
                                .detail-item .label {
                                    font-size: 0.75rem;
                                    color: var(--text-secondary);
                                    text-transform: uppercase;
                                    letter-spacing: 0.05em;
                                    margin-bottom: 0.25rem;
                                }
                                .detail-item .value {
                                    font-weight: 600;
                                    font-size: 0.9375rem;
                                }
                            `}</style>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}
