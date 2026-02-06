import React, { useEffect, useState } from 'react';
import { fetchEvents, deleteEvent } from '../api';
import { Trash2, Search, MapPin, Calendar as CalIcon, Users } from 'lucide-react';

export default function EventsPage({ token }) {
    const [events, setEvents] = useState([]);
    const [filteredEvents, setFilteredEvents] = useState([]);
    const [search, setSearch] = useState('');
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadData();
    }, []);

    useEffect(() => {
        setFilteredEvents(
            events.filter(e =>
                e.title.toLowerCase().includes(search.toLowerCase()) ||
                (e.location && e.location.toLowerCase().includes(search.toLowerCase()))
            )
        );
    }, [search, events]);

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
        if (!confirm('Вы уверены, что хотите удалить это мероприятие?')) return;
        try {
            await deleteEvent(token, id);
            setEvents(prev => prev.filter(e => e.id !== id));
        } catch (e) {
            alert('Ошибка удаления: ' + e.message);
        }
    };

    return (
        <div className="animate-fade-in">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <div>
                    <h1>Мероприятия</h1>
                    <p>Все события на платформе</p>
                </div>
                <div style={{ position: 'relative' }}>
                    <Search size={20} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#9CA3AF' }} />
                    <input
                        type="text"
                        placeholder="Поиск мероприятий..."
                        value={search}
                        onChange={e => setSearch(e.target.value)}
                        style={{ paddingLeft: '2.5rem', width: '300px' }}
                    />
                </div>
            </div>

            <div className="grid-cols-1 grid-cols-2">
                {filteredEvents.map(event => (
                    <div key={event.id} className="glass-card" style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                            <div>
                                <span style={{
                                    fontSize: '0.7rem',
                                    textTransform: 'uppercase',
                                    fontWeight: 600,
                                    color: '#983296',
                                    background: '#F3E8FF',
                                    padding: '2px 6px',
                                    borderRadius: '4px'
                                }}>
                                    {event.category || 'Без категории'}
                                </span>
                                <h3 style={{ margin: '0.5rem 0', fontSize: '1.1rem' }}>{event.title}</h3>
                            </div>
                            <button
                                onClick={() => handleDelete(event.id)}
                                style={{ padding: '6px', borderRadius: '4px', border: 'none', background: 'transparent', color: '#EF4444', cursor: 'pointer' }}
                                title="Удалить"
                            >
                                <Trash2 size={18} />
                            </button>
                        </div>

                        <p style={{ fontSize: '0.9rem', color: '#52525B', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden', margin: 0 }}>
                            {event.description}
                        </p>

                        <div style={{ display: 'flex', gap: '1rem', fontSize: '0.85rem', color: '#6B7280', marginTop: 'auto', paddingTop: '1rem', borderTop: '1px solid #F3F4F6' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                                <CalIcon size={14} />
                                {event.date_text}
                            </div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                                <MapPin size={14} />
                                {event.location || 'Онлайн'}
                            </div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginLeft: 'auto' }}>
                                <Users size={14} />
                                {event.volunteer_count} / {event.hours}h
                            </div>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}
