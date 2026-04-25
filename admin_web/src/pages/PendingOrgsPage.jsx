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
    Filter
} from 'lucide-react';

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

                <div style={{ display: 'flex', gap: '1rem' }}>
                    <div style={{ position: 'relative' }}>
                        <Search size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
                        <input
                            type="text"
                            placeholder="Поиск по названию или БИН..."
                            className="search-input"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            style={{ paddingLeft: '2.5rem', width: '300px' }}
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
                <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '1.5rem' }}>
                    {filteredOrgs.map((org) => (
                        <div key={org.id} className="card org-card">
                            <div className="org-card-header">
                                <div className="org-meta">
                                    <div className="org-icon">
                                        <Building2 size={24} />
                                    </div>
                                    <div>
                                        <h3>{org.org_name || 'Без названия'}</h3>
                                        <div className="org-badges">
                                            <span className="badge badge-warning">На проверке</span>
                                            <span className="badge" style={{ background: '#f1f5f9', color: '#475569' }}>ID: {org.id}</span>
                                        </div>
                                    </div>
                                </div>
                                <div className="org-actions">
                                    <button
                                        className="btn btn-outline"
                                        onClick={() => {/* Посмотреть подробнее */ }}
                                    >
                                        <ShieldAlert size={16} />
                                        Проверить
                                    </button>
                                    <button
                                        className="btn btn-primary"
                                        disabled={processingId === org.id}
                                        onClick={() => handleApprove(org.id)}
                                    >
                                        <CheckCircle2 size={16} />
                                        {processingId === org.id ? 'Одобрение...' : 'Одобрить'}
                                    </button>
                                </div>
                            </div>

                            <div className="org-details-grid">
                                <div className="detail-item">
                                    <Hash size={16} className="detail-icon" />
                                    <div>
                                        <p className="label">БИН/ИИН</p>
                                        <p className="value">{org.bin || '-—'}</p>
                                    </div>
                                </div>
                                <div className="detail-item">
                                    <MapPin size={16} className="detail-icon" />
                                    <div>
                                        <p className="label">Адрес</p>
                                        <p className="value">{org.address || 'Казахстан, Алматы'}</p>
                                    </div>
                                </div>
                                <div className="detail-item">
                                    <ShieldAlert size={16} className="detail-icon" />
                                    <div>
                                        <p className="label">Тип организации</p>
                                        <p className="value">Благотворительный фонд</p>
                                    </div>
                                </div>
                                <div className="detail-item">
                                    <ExternalLink size={16} className="detail-icon" />
                                    <div>
                                        <p className="label">Email владельца</p>
                                        <p className="value">{org.email}</p>
                                    </div>
                                </div>
                            </div>

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
