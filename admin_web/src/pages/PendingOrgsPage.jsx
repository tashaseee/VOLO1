import React, { useEffect, useState } from 'react';
import { fetchPendingOrgs, approveOrg } from '../api';
import { CheckCircle, Clock, Building, Mail, Phone, Globe, FileText } from 'lucide-react';

export default function PendingOrgsPage({ token }) {
    const [pendingOrgs, setPendingOrgs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [processingId, setProcessingId] = useState(null);

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        setLoading(true);
        try {
            const data = await fetchPendingOrgs(token);
            setPendingOrgs(data);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    const handleApprove = async (id) => {
        if (!confirm('Вы уверены, что хотите одобрить эту организацию?')) return;
        setProcessingId(id);
        try {
            await approveOrg(token, id);
            // Remove from list
            setPendingOrgs(prev => prev.filter(org => org.id !== id));
        } catch (err) {
            alert('Ошибка при одобрении: ' + err.message);
        } finally {
            setProcessingId(null);
        }
    };

    return (
        <div style={{ paddingBottom: '4rem' }}>


            <main className="container animate-fade-in">
                <div style={{ marginBottom: '2rem' }}>
                    <h1>Заявки организаций</h1>
                    <p>Просмотр и одобрение заявок на регистрацию организаций.</p>
                </div>

                {loading ? (
                    <div className="flex-center" style={{ padding: '4rem' }}>
                        <div style={{ width: '40px', height: '40px', border: '3px solid rgba(152, 50, 150, 0.3)', borderTopColor: '#983296', borderRadius: '50%', animation: 'spin 1s linear infinite' }}></div>
                        <style>{`@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }`}</style>
                    </div>
                ) : error ? (
                    <div className="glass-card" style={{ color: '#ef4444', textAlign: 'center', background: '#FEF2F2', border: '1px solid #FECACA' }}>
                        Ошибка: {error}
                        <br />
                        <button className="btn btn-primary" onClick={loadData} style={{ marginTop: '1rem' }}>Повторить</button>
                    </div>
                ) : pendingOrgs.length === 0 ? (
                    <div className="glass-card flex-center" style={{ padding: '4rem', flexDirection: 'column', color: 'var(--text-secondary)' }}>
                        <CheckCircle size={48} style={{ marginBottom: '1rem', opacity: 0.2, color: '#983296' }} />
                        <h3>Все заявки обработаны!</h3>
                        <p>На данный момент нет новых заявок от организаций.</p>
                    </div>
                ) : (
                    <div className="grid-cols-1 grid-cols-2">
                        {pendingOrgs.map(org => (
                            <div key={org.id} className="glass-card" style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                                    <div>
                                        <h2 style={{ margin: 0, fontSize: '1.25rem', marginBottom: '0.25rem' }}>{org.org_name}</h2>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                                            <span className="label" style={{ background: '#F3E8FF', color: '#983296', padding: '4px 8px', borderRadius: '4px', fontSize: '0.7rem' }}>БИН: {org.bin}</span>
                                            <span className="label" style={{ background: '#ECFDF5', color: '#059669', padding: '4px 8px', borderRadius: '4px', fontSize: '0.7rem' }}>Новая заявка</span>
                                        </div>
                                    </div>
                                    <div style={{ background: '#F8F9FA', padding: '0.5rem', borderRadius: '8px' }}>
                                        <Clock size={20} color="#95969D" />
                                    </div>
                                </div>

                                <div style={{ height: '1px', background: '#F1F1F1', margin: '0' }}></div>

                                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem 1rem' }}>
                                    <div className="list-item-content">
                                        <span className="label"><Mail size={12} style={{ display: 'inline', marginRight: '4px', verticalAlign: 'middle' }} /> Email</span>
                                        <div className="value">{org.email}</div>
                                    </div>
                                    <div className="list-item-content">
                                        <span className="label"><Phone size={12} style={{ display: 'inline', marginRight: '4px', verticalAlign: 'middle' }} /> Телефон</span>
                                        <div className="value">{org.phone}</div>
                                    </div>
                                    <div className="list-item-content" style={{ gridColumn: 'span 2' }}>
                                        <span className="label"><Globe size={12} style={{ display: 'inline', marginRight: '4px', verticalAlign: 'middle' }} /> Веб-сайт / Instagram</span>
                                        <div className="value">
                                            {org.website !== 'Не указано' ? (
                                                <a href={org.website.startsWith('http') ? org.website : `https://${org.website}`} target="_blank" rel="noopener noreferrer" style={{ color: '#983296', textDecoration: 'none', fontWeight: '500' }}>
                                                    {org.website}
                                                </a>
                                            ) : 'Не указано'}
                                        </div>
                                    </div>
                                    <div className="list-item-content" style={{ gridColumn: 'span 2' }}>
                                        <span className="label"><FileText size={12} style={{ display: 'inline', marginRight: '4px', verticalAlign: 'middle' }} /> Описание</span>
                                        <div className="value" style={{ fontSize: '0.9rem', color: '#52525B', lineHeight: '1.5' }}>{org.description}</div>
                                    </div>
                                </div>

                                <div style={{ marginTop: 'auto', paddingTop: '1rem' }}>
                                    <button
                                        className="btn btn-primary"
                                        style={{ width: '100%', background: '#10b981', boxShadow: '0 4px 10px rgba(16, 185, 129, 0.2)' }}
                                        onClick={() => handleApprove(org.id)}
                                        disabled={processingId === org.id}
                                    >
                                        {processingId === org.id ? 'Обработка...' : (
                                            <>
                                                <CheckCircle size={18} /> Одобрить организацию
                                            </>
                                        )}
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </main>
        </div>
    );
}
