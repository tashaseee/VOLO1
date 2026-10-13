import React, { useEffect, useState } from 'react';
import { fetchSupportRequests, replyToSupportRequest } from '../api';
import {
    MessageSquare,
    CheckCircle2,
    Clock,
    Search,
    Send,
    HelpCircle,
    User,
    AlertCircle
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

export default function SupportTicketsPage({ token }) {
    const [tickets, setTickets] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState('all'); // all, pending, resolved
    const [replyTexts, setReplyTexts] = useState({}); // ticketId -> text
    const [submittingId, setSubmittingId] = useState(null);

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setLoading(true);
            const data = await fetchSupportRequests(token);
            setTickets(data);
        } catch (e) {
            console.error('Error fetching support tickets:', e);
        } finally {
            setLoading(false);
        }
    };

    const handleReplySubmit = async (e, ticketId) => {
        e.preventDefault();
        const text = replyTexts[ticketId]?.trim();
        if (!text) return;

        setSubmittingId(ticketId);
        try {
            await replyToSupportRequest(token, ticketId, text);
            // Update local state to show resolved
            setTickets(tickets.map(t => {
                if (t.id === ticketId) {
                    return {
                        ...t,
                        status: 'resolved',
                        reply: text,
                        replied_at: new Date().toISOString()
                    };
                }
                return t;
            }));
            // Clear textbox
            setReplyTexts(prev => ({ ...prev, [ticketId]: '' }));
        } catch (error) {
            alert('Ошибка при отправке ответа: ' + error.message);
        } finally {
            setSubmittingId(null);
        }
    };

    const handleTextChange = (ticketId, value) => {
        setReplyTexts(prev => ({
            ...prev,
            [ticketId]: value
        }));
    };

    const formatDate = (dateStr) => {
        if (!dateStr) return '';
        try {
            const date = new Date(dateStr);
            return date.toLocaleString('ru-RU', {
                day: '2-digit',
                month: '2-digit',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        } catch (_) {
            return dateStr;
        }
    };

    // Filter tickets
    const filteredTickets = tickets.filter(ticket => {
        const matchesStatus = 
            statusFilter === 'all' || 
            (statusFilter === 'pending' && ticket.status === 'pending') || 
            (statusFilter === 'resolved' && ticket.status === 'resolved');

        const matchesSearch = 
            ticket.user_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            ticket.user_email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            ticket.message?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            String(ticket.id).includes(searchTerm);

        return matchesStatus && matchesSearch;
    });

    const pendingCount = tickets.filter(t => t.status === 'pending').length;
    const resolvedCount = tickets.filter(t => t.status === 'resolved').length;

    if (loading) {
        return <div className="animate-pulse flex-center" style={{ height: '400px' }}>Загрузка обращений...</div>;
    }

    return (
        <div className="animate-slide-in">
            <header style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', flexWrap: 'wrap', gap: '1.5rem' }}>
                <div>
                    <h1>Техническая поддержка</h1>
                    <p className="page-description">Обращения пользователей платформы VOLO</p>
                </div>

                <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', flexWrap: 'wrap' }}>
                    {/* Search Input */}
                    <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
                        <Search size={18} style={{ position: 'absolute', left: '16px', color: 'var(--primary)' }} />
                        <input
                            type="text"
                            placeholder="Поиск по имени, почте, сообщению..."
                            className="search-input"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            style={{ 
                                paddingLeft: '3rem', 
                                paddingRight: '1rem',
                                width: '320px',
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

            {/* Stats Dashboard Grid */}
            <div className="stats-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1.5rem', marginBottom: '2.5rem' }}>
                <div className="card stat-card" style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', padding: '1.5rem' }}>
                    <div className="stat-icon" style={{ background: 'var(--primary-light)', color: 'var(--primary)', width: '48px', height: '48px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <MessageSquare size={24} />
                    </div>
                    <div>
                        <p style={{ margin: 0, fontSize: '0.85rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Всего обращений</p>
                        <h2 style={{ margin: 0, fontSize: '1.8rem', fontWeight: 800 }}>{tickets.length}</h2>
                    </div>
                </div>
                
                <div className="card stat-card" style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', padding: '1.5rem' }}>
                    <div className="stat-icon" style={{ background: '#fef3c7', color: '#d97706', width: '48px', height: '48px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Clock size={24} />
                    </div>
                    <div>
                        <p style={{ margin: 0, fontSize: '0.85rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Ожидают ответа</p>
                        <h2 style={{ margin: 0, fontSize: '1.8rem', fontWeight: 800, color: '#d97706' }}>{pendingCount}</h2>
                    </div>
                </div>

                <div className="card stat-card" style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', padding: '1.5rem' }}>
                    <div className="stat-icon" style={{ background: 'var(--success-bg)', color: 'var(--success)', width: '48px', height: '48px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <CheckCircle2 size={24} />
                    </div>
                    <div>
                        <p style={{ margin: 0, fontSize: '0.85rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Решенные тикеты</p>
                        <h2 style={{ margin: 0, fontSize: '1.8rem', fontWeight: 800, color: 'var(--success)' }}>{resolvedCount}</h2>
                    </div>
                </div>
            </div>

            {/* Status Filter Tabs */}
            <div className="tabs-container" style={{ display: 'flex', borderBottom: '1px solid var(--border)', marginBottom: '2rem', gap: '2rem' }}>
                <button 
                    onClick={() => setStatusFilter('all')} 
                    style={{ 
                        padding: '1rem 0.5rem', 
                        border: 'none', 
                        background: 'none', 
                        borderBottom: statusFilter === 'all' ? '3px solid var(--primary)' : '3px solid transparent',
                        color: statusFilter === 'all' ? 'var(--primary-dark)' : 'var(--text-secondary)',
                        fontWeight: '700',
                        fontSize: '0.95rem',
                        cursor: 'pointer',
                        transition: 'all 0.2s'
                    }}
                >
                    Все
                </button>
                <button 
                    onClick={() => setStatusFilter('pending')} 
                    style={{ 
                        padding: '1rem 0.5rem', 
                        border: 'none', 
                        background: 'none', 
                        borderBottom: statusFilter === 'pending' ? '3px solid var(--primary)' : '3px solid transparent',
                        color: statusFilter === 'pending' ? 'var(--primary-dark)' : 'var(--text-secondary)',
                        fontWeight: '700',
                        fontSize: '0.95rem',
                        cursor: 'pointer',
                        transition: 'all 0.2s',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.5rem'
                    }}
                >
                    В обработке
                    {pendingCount > 0 && <span style={{ background: '#d97706', color: 'white', fontSize: '0.75rem', padding: '2px 6px', borderRadius: '10px' }}>{pendingCount}</span>}
                </button>
                <button 
                    onClick={() => setStatusFilter('resolved')} 
                    style={{ 
                        padding: '1rem 0.5rem', 
                        border: 'none', 
                        background: 'none', 
                        borderBottom: statusFilter === 'resolved' ? '3px solid var(--primary)' : '3px solid transparent',
                        color: statusFilter === 'resolved' ? 'var(--primary-dark)' : 'var(--text-secondary)',
                        fontWeight: '700',
                        fontSize: '0.95rem',
                        cursor: 'pointer',
                        transition: 'all 0.2s'
                    }}
                >
                    Отвечено
                </button>
            </div>

            {/* Support Requests List */}
            {filteredTickets.length === 0 ? (
                <div className="card" style={{ textAlign: 'center', padding: '5rem 2rem' }}>
                    <div style={{ background: 'var(--border)', color: 'var(--text-secondary)', width: '64px', height: '64px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 1.5rem' }}>
                        <HelpCircle size={32} />
                    </div>
                    <h2>Обращений не найдено</h2>
                    <p style={{ color: 'var(--text-secondary)' }}>Попробуйте изменить поисковый запрос или фильтр.</p>
                </div>
            ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                    {filteredTickets.map((ticket) => {
                        const isPending = ticket.status === 'pending';
                        
                        return (
                            <div key={ticket.id} className="card" style={{ padding: '2rem', borderLeft: isPending ? '4px solid #f59e0b' : '4px solid var(--success)' }}>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '1rem', marginBottom: '1.25rem' }}>
                                    
                                    {/* User Details */}
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                        <div style={{ 
                                            width: '44px', 
                                            height: '44px', 
                                            borderRadius: '12px', 
                                            background: isPending ? '#fef3c7' : 'var(--success-bg)', 
                                            color: isPending ? '#d97706' : 'var(--success)', 
                                            display: 'flex', 
                                            alignItems: 'center', 
                                            justifyContent: 'center',
                                            fontWeight: 'bold',
                                            fontSize: '1rem'
                                        }}>
                                            {ticket.user_name ? ticket.user_name.substring(0, 2).toUpperCase() : <User size={20} />}
                                        </div>
                                        <div>
                                            <h4 style={{ margin: 0, fontSize: '1.05rem', fontWeight: 800 }}>
                                                {highlightMatch(ticket.user_name, searchTerm)}
                                            </h4>
                                            <p style={{ margin: 0, fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 500 }}>
                                                {highlightMatch(ticket.user_email, searchTerm)}
                                            </p>
                                        </div>
                                    </div>

                                    {/* Status Badge & Time */}
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', flexWrap: 'wrap' }}>
                                        <span className={`badge ${isPending ? 'badge-warning' : 'badge-success'}`} style={{ fontSize: '0.75rem', fontWeight: 'bold' }}>
                                            {isPending ? 'В обработке' : 'Отвечено'}
                                        </span>
                                        <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 500 }}>
                                            {formatDate(ticket.created_at)}
                                        </span>
                                    </div>
                                </div>

                                {/* User Question Message */}
                                <div style={{ 
                                    background: '#f8fafc', 
                                    padding: '1.25rem 1.5rem', 
                                    borderRadius: '12px', 
                                    border: '1px solid var(--border)',
                                    marginBottom: '1.5rem'
                                }}>
                                    <p style={{ margin: 0, fontSize: '0.75rem', color: 'var(--text-secondary)', marginBottom: '0.5rem', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.03em' }}>Вопрос пользователя:</p>
                                    <p style={{ margin: 0, fontSize: '0.95rem', color: 'var(--text-primary)', whiteSpace: 'pre-line', lineHeight: '1.5' }}>
                                        {highlightMatch(ticket.message, searchTerm)}
                                    </p>
                                </div>

                                {/* Reply Section */}
                                {ticket.reply ? (
                                    /* Resolved view */
                                    <div style={{ 
                                        background: 'var(--primary-light)', 
                                        padding: '1.25rem 1.5rem', 
                                        borderRadius: '12px', 
                                        border: '1px solid rgba(152, 50, 150, 0.1)',
                                    }}>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                                            <p style={{ margin: 0, fontSize: '0.75rem', color: 'var(--primary-dark)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.03em' }}>Ответ техподдержки:</p>
                                            <span style={{ fontSize: '0.75rem', color: 'var(--primary-dark)', fontWeight: 500 }}>
                                                {formatDate(ticket.replied_at)}
                                            </span>
                                        </div>
                                        <p style={{ margin: 0, fontSize: '0.95rem', color: 'var(--primary-dark)', whiteSpace: 'pre-line', lineHeight: '1.5' }}>
                                            {ticket.reply}
                                        </p>
                                    </div>
                                ) : (
                                    /* Pending reply form */
                                    <form onSubmit={(e) => handleReplySubmit(e, ticket.id)}>
                                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                                            <textarea
                                                rows="3"
                                                placeholder="Введите ваш ответ для волонтера..."
                                                value={replyTexts[ticket.id] || ''}
                                                onChange={(e) => handleTextChange(ticket.id, e.target.value)}
                                                style={{ 
                                                    width: '100%', 
                                                    padding: '1rem', 
                                                    borderRadius: '12px', 
                                                    border: '2px solid var(--border)',
                                                    fontSize: '0.95rem', 
                                                    fontFamily: 'inherit',
                                                    resize: 'vertical',
                                                    outline: 'none',
                                                    transition: 'all 0.2s',
                                                    boxSizing: 'border-box'
                                                }}
                                                onFocus={(e) => e.target.style.borderColor = 'var(--primary)'}
                                                onBlur={(e) => e.target.style.borderColor = 'var(--border)'}
                                            />
                                            <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                                                <button
                                                    type="submit"
                                                    disabled={submittingId === ticket.id || !replyTexts[ticket.id]?.trim()}
                                                    className="btn btn-primary"
                                                    style={{ 
                                                        height: '42px', 
                                                        padding: '0 1.5rem', 
                                                        fontSize: '0.85rem',
                                                        display: 'flex',
                                                        alignItems: 'center',
                                                        gap: '0.5rem',
                                                        borderRadius: '10px'
                                                    }}
                                                >
                                                    <Send size={14} />
                                                    {submittingId === ticket.id ? 'Отправка...' : 'Отправить ответ'}
                                                </button>
                                            </div>
                                        </div>
                                    </form>
                                )}
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
}
