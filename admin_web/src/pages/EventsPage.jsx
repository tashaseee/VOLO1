import React, { useEffect, useState } from 'react';
import { fetchEvents, deleteEvent, fetchEventDetail, toggleEventActive, mediaUrl } from '../api';
import {
    Calendar,
    MapPin,
    Users,
    Trash2,
    Search,
    Clock,
    Briefcase,
    ExternalLink,
    ChevronRight,
    ShieldAlert,
    X,
    CheckCircle,
    Ban,
    Info,
    Building
} from 'lucide-react';

export default function EventsPage({ token }) {
    const [events, setEvents] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [selectedEvent, setSelectedEvent] = useState(null);
    const [detailLoading, setDetailLoading] = useState(false);

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        setLoading(true);
        try {
            const data = await fetchEvents(token);
            setEvents(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Вы уверены, что хотите удалить это мероприятие? Это действие необратимо.')) return;
        try {
            await deleteEvent(token, id);
            setEvents(events.filter(e => e.id !== id));
            if (selectedEvent?.id === id) setSelectedEvent(null);
        } catch (e) {
            alert(e.message);
        }
    };

    const handleToggleActive = async (id) => {
        try {
            const result = await toggleEventActive(token, id);
            setEvents(events.map(e => e.id === id ? { ...e, is_active: result.is_active } : e));
            if (selectedEvent?.id === id) setSelectedEvent({ ...selectedEvent, is_active: result.is_active });
        } catch (e) {
            alert(e.message);
        }
    };

    const handleViewDetail = async (eventId) => {
        setDetailLoading(true);
        try {
            const data = await fetchEventDetail(token, eventId);
            setSelectedEvent(data);
        } catch (e) {
            alert('Ошибка при загрузке данных: ' + e.message);
        } finally {
            setDetailLoading(false);
        }
    };

    const filteredEvents = events.filter(e =>
        e.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        e.organizer?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const getImageUrl = (url) => mediaUrl(url) || null;

    return (
        <div className="animate-slide-in">
            <header style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
                <div>
                    <h1>Мероприятия</h1>
                    <p className="page-description">Модерация волонтерских инициатив платформы ({events.length})</p>
                </div>

                <div style={{ position: 'relative' }}>
                    <Search size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
                    <input
                        type="text"
                        placeholder="Поиск по названию или организатору..."
                        className="search-input"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        style={{
                            padding: '0.625rem 1rem 0.625rem 2.5rem',
                            border: '1px solid var(--border)',
                            borderRadius: 'var(--radius)',
                            width: '320px',
                            outline: 'none'
                        }}
                    />
                </div>
            </header>

            <div className="events-grid">
                {loading ? (
                    <div style={{ padding: '3rem', textAlign: 'center', gridColumn: '1/-1' }}>Загрузка...</div>
                ) : filteredEvents.length === 0 ? (
                    <div style={{ padding: '3rem', textAlign: 'center', gridColumn: '1/-1' }}>Мероприятия не найдены.</div>
                ) : filteredEvents.map((event) => (
                    <div key={event.id} className="card event-admin-card" onClick={() => handleViewDetail(event.id)}>
                        <div className="event-cover-wrapper">
                            {event.image_url ? (
                                <img src={getImageUrl(event.image_url)} alt={event.title} className="event-cover-img" />
                            ) : (
                                <div className="event-cover-placeholder">
                                    <Calendar size={48} opacity={0.2} />
                                </div>
                            )}
                            <div className={`status-overlay ${event.is_active ? 'active' : 'inactive'}`}>
                                {event.is_active ? 'Активно' : 'Заблокировано'}
                            </div>
                        </div>

                        <div className="event-content">
                            <div className="event-info-main">
                                <span className="event-category-tag">{event.category || 'Общее'}</span>
                                <h3 className="event-title-truncate">{event.title}</h3>
                                <div className="event-meta-row">
                                    <Building size={14} />
                                    <span>{event.organizer || 'Организация'}</span>
                                </div>
                                <div className="event-meta-row">
                                    <MapPin size={14} />
                                    <span>{event.location}</span>
                                </div>
                            </div>

                            <div className="event-stats-row">
                                <div className="stat-item">
                                    <Users size={14} />
                                    <span>{event.volunteer_count} чел</span>
                                </div>
                                <div className="stat-item">
                                    <Clock size={14} />
                                    <span>{event.hours} ч</span>
                                </div>
                            </div>

                            <div className="event-actions" onClick={e => e.stopPropagation()}>
                                <button
                                    className={`btn ${event.is_active ? 'btn-outline' : 'btn-primary'}`}
                                    onClick={() => handleToggleActive(event.id)}
                                    title={event.is_active ? "Деактивировать" : "Активировать"}
                                >
                                    {event.is_active ? <Ban size={16} /> : <CheckCircle size={16} />}
                                </button>
                                <button
                                    className="btn btn-danger-outline"
                                    onClick={() => handleDelete(event.id)}
                                    title="Удалить навсегда"
                                >
                                    <Trash2 size={16} />
                                </button>
                                <button
                                    className="btn btn-outline"
                                    onClick={() => handleViewDetail(event.id)}
                                >
                                    Подробнее
                                </button>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            {/* Event Detail Modal */}
            {selectedEvent && (
                <div className="modal-overlay" onClick={() => setSelectedEvent(null)}>
                    <div className="modal-content animate-slide-in" onClick={e => e.stopPropagation()} style={{ maxWidth: '850px' }}>
                        <button className="close-btn" onClick={() => setSelectedEvent(null)}>
                            <X size={20} />
                        </button>

                        <div className="modal-cover-section">
                            {selectedEvent.image_url ? (
                                <img src={getImageUrl(selectedEvent.image_url)} alt="" className="modal-cover-img" />
                            ) : (
                                <div className="modal-cover-placeholder">Нет обложки</div>
                            )}
                            <div className="modal-cover-overlay">
                                <span className="category-label">{selectedEvent.category}</span>
                                <h2 className="modal-event-title">{selectedEvent.title}</h2>
                            </div>
                        </div>

                        <div className="modal-body" style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '2rem' }}>
                            <div className="main-info">
                                <div className="info-block">
                                    <h3>Описание</h3>
                                    <p className="description-text">{selectedEvent.description}</p>
                                </div>
                                <div className="info-block">
                                    <h3>Обязанности волонтера</h3>
                                    <p className="description-text">{selectedEvent.responsibilities || 'Не указаны'}</p>
                                </div>
                                <div className="info-block">
                                    <h3>Преимущества / Бонусы</h3>
                                    <p className="description-text">{selectedEvent.benefits || 'Не указаны'}</p>
                                </div>
                            </div>

                            <div className="side-info">
                                <div className="stat-summary-card">
                                    <div className="summary-item">
                                        <div className="summary-icon"><Clock size={16} /></div>
                                        <div>
                                            <p className="summary-label">Часов помощи</p>
                                            <p className="summary-value">{selectedEvent.hours} ч</p>
                                        </div>
                                    </div>
                                    <div className="summary-item">
                                        <div className="summary-icon"><Users size={16} /></div>
                                        <div>
                                            <p className="summary-label">Нужно волонтеров</p>
                                            <p className="summary-value">{selectedEvent.volunteer_count} чел</p>
                                        </div>
                                    </div>
                                    <div className="summary-item">
                                        <div className="summary-icon"><Calendar size={16} /></div>
                                        <div>
                                            <p className="summary-label">Дата проведения</p>
                                            <p className="summary-value">{selectedEvent.date_text || 'Не указана'}</p>
                                        </div>
                                    </div>
                                </div>

                                <div className="org-card-mini">
                                    <Building size={20} />
                                    <div>
                                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', margin: 0 }}>Организатор</p>
                                        <p style={{ fontWeight: '600', margin: 0 }}>{selectedEvent.organizer}</p>
                                    </div>
                                </div>

                                <div className="moderation-controls">
                                    <h4 style={{ fontSize: '0.875rem', marginBottom: '1rem' }}>Модерация</h4>
                                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                                        <button
                                            className={`btn ${selectedEvent.is_active ? 'btn-danger-outline' : 'btn-primary'}`}
                                            onClick={() => handleToggleActive(selectedEvent.id)}
                                            style={{ width: '100%', justifyContent: 'center' }}
                                        >
                                            {selectedEvent.is_active ? <Ban size={16} /> : <CheckCircle size={16} />}
                                            {selectedEvent.is_active ? 'Деактивировать' : 'Активировать'}
                                        </button>
                                        <button
                                            className="btn btn-danger-outline"
                                            onClick={() => handleDelete(selectedEvent.id)}
                                            style={{ width: '100%', justifyContent: 'center' }}
                                        >
                                            <Trash2 size={16} />
                                            Удалить навсегда
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            <style jsx="true">{`
                .events-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
                    gap: 1.5rem;
                }

                .event-admin-card {
                    padding: 0;
                    overflow: hidden;
                    display: flex;
                    flex-direction: column;
                    cursor: pointer;
                    transition: transform 0.2s, box-shadow 0.2s;
                }

                .event-admin-card:hover {
                    transform: translateY(-4px);
                    box-shadow: var(--shadow-lg);
                }

                .event-cover-wrapper {
                    height: 160px;
                    position: relative;
                    background: #f1f5f9;
                }

                .event-cover-img {
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                }

                .event-cover-placeholder {
                    width: 100%;
                    height: 100%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    color: var(--text-muted);
                }

                .status-overlay {
                    position: absolute;
                    top: 0.75rem;
                    right: 0.75rem;
                    padding: 0.25rem 0.75rem;
                    border-radius: 20px;
                    font-size: 0.75rem;
                    font-weight: 700;
                    backdrop-filter: blur(4px);
                    color: white;
                }

                .status-overlay.active { background: rgba(16, 185, 129, 0.9); }
                .status-overlay.inactive { background: rgba(239, 68, 68, 0.9); }

                .event-content {
                    padding: 1.25rem;
                    display: flex;
                    flex-direction: column;
                    flex: 1;
                }

                .event-category-tag {
                    font-size: 0.625rem;
                    text-transform: uppercase;
                    letter-spacing: 0.05em;
                    font-weight: 700;
                    color: var(--primary);
                    margin-bottom: 0.5rem;
                    display: block;
                }

                .event-title-truncate {
                    font-size: 1.125rem;
                    font-weight: 700;
                    margin: 0 0 0.75rem 0;
                    display: -webkit-box;
                    -webkit-line-clamp: 2;
                    -webkit-box-orient: vertical;
                    overflow: hidden;
                    line-height: 1.4;
                    min-height: 3.1rem;
                }

                .event-meta-row {
                    display: flex;
                    align-items: center;
                    gap: 0.5rem;
                    font-size: 0.8125rem;
                    color: var(--text-secondary);
                    margin-bottom: 0.375rem;
                }

                .event-stats-row {
                    display: flex;
                    gap: 1rem;
                    margin-top: 1rem;
                    padding-top: 1rem;
                    border-top: 1px solid var(--border);
                }

                .stat-item {
                    display: flex;
                    align-items: center;
                    gap: 0.375rem;
                    font-size: 0.75rem;
                    font-weight: 600;
                    color: var(--text-muted);
                }

                .event-actions {
                    display: flex;
                    gap: 0.5rem;
                    margin-top: 1.25rem;
                }

                .event-actions .btn {
                    padding: 0.5rem;
                    flex: 0;
                }

                .event-actions .btn:last-child {
                    flex: 1;
                }

                .modal-overlay {
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: rgba(15, 23, 42, 0.7);
                    display: flex;
                    align-items: flex-start; /* Start from top as user requested */
                    justify-content: center;
                    z-index: 2000;
                    backdrop-filter: blur(8px);
                    padding: 40px 20px;
                    overflow-y: auto;
                }

                .modal-content {
                    background: white;
                    width: 100%;
                    max-width: 850px;
                    border-radius: var(--radius-lg);
                    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
                    position: relative;
                    margin: 0 auto;
                }

                .close-btn {
                    position: absolute;
                    top: 1rem;
                    right: 1rem;
                    z-index: 10;
                    background: white;
                    border: none;
                    width: 32px;
                    height: 32px;
                    border-radius: 50%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    cursor: pointer;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                    color: var(--text-main);
                }

                .modal-cover-section {
                    height: 300px;
                    position: relative;
                    border-radius: var(--radius-lg) var(--radius-lg) 0 0;
                    overflow: hidden;
                    background: #1e293b;
                }

                .modal-cover-img {
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                }

                .modal-cover-overlay {
                    position: absolute;
                    inset: 0;
                    background: linear-gradient(to top, rgba(15, 23, 42, 0.95), rgba(15, 23, 42, 0.4), transparent);
                    display: flex;
                    flex-direction: column;
                    justify-content: flex-end;
                    padding: 2rem;
                    color: white;
                }

                .modal-event-title {
                    font-size: 1.75rem;
                    margin: 0.5rem 0 0;
                    font-weight: 800;
                    line-height: 1.2;
                }

                .modal-body {
                    padding: 2rem;
                }

                .info-block { margin-bottom: 2rem; }
                .info-block h3 { margin-bottom: 0.75rem; font-size: 1.125rem; }

                .stat-summary-card {
                    background: #f8fafc;
                    border: 1px solid var(--border);
                    border-radius: 12px;
                    padding: 1.25rem;
                    margin-bottom: 1.5rem;
                }

                .summary-item {
                    display: flex;
                    align-items: flex-start;
                    gap: 1rem;
                    margin-bottom: 1.25rem;
                }
                .summary-item:last-child { margin-bottom: 0; }
                
                .summary-icon {
                    background: var(--primary-light);
                    color: var(--primary);
                    padding: 8px;
                    border-radius: 8px;
                    display: flex;
                }
            `}</style>
        </div >
    );
}
